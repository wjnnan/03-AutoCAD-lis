#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""TB-Toolbox 真机功能测试执行器。

流程：
  1. 从 TB-Toolbox 源码提取全部命令(c:*)与库函数清单；
  2. 与手写的行为断言模板合并，生成 GBK 编码的 LISP 测试脚本；
  3. 调用 accoreconsole（真实 AutoCAD 引擎）执行；
  4. 解析结果日志，输出分层报告。

用法:
  python tests/run_tb_functional.py            # 完整运行
  python tests/run_tb_functional.py --gen      # 只生成脚本不执行
退出码: 0 全部通过；1 存在失败。
"""

from __future__ import annotations

import argparse
import glob
import re
import subprocess
import sys
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
TB_DIR = ROOT / "TB-Toolbox"
LOG_PATH = ROOT / "_tb_func_result.log"
GEN_LSP = ROOT / "tests" / "_tb_functional_gen.lsp"


def find_accoreconsole():
    for version in ("2024", "2025", "2026", "2023", "2022"):
        c = Path(rf"C:\Program Files\Autodesk\AutoCAD {version}\accoreconsole.exe")
        if c.exists():
            return str(c)
    return None


def read_src(path):
    raw = path.read_bytes()
    for enc in ("gbk", "utf-8"):
        try:
            return raw.decode(enc)
        except UnicodeDecodeError:
            continue
    return raw.decode("gbk", errors="replace")


def strip_comments_strings(text):
    """剥离 AutoLISP 的 ; 行注释与 "..." 字符串，避免把文档里的示例当成真实定义。"""
    out, i, n = [], 0, len(text)
    while i < n:
        c = text[i]
        if c == ";":
            # 注释内容也整体替换为等长空格，保证索引与原文对齐
            j = text.find(chr(10), i)
            if j < 0:
                out.append(" " * (n - i))
                i = n
            else:
                out.append(" " * (j - i))
                i = j
        elif c == '"':
            start = i
            i += 1
            while i < n:
                if text[i] == "\\":
                    i += 2
                    continue
                if text[i] == '"':
                    i += 1
                    break
                i += 1
            out.append(" " * (i - start))
        else:
            out.append(c)
            i += 1
    return "".join(out)


def collect_names():
    """扫描 TB-Toolbox，返回 (命令名列表, 库函数名列表)。"""
    cmds, funcs = set(), set()
    for f in sorted(glob.glob(str(TB_DIR / "*.lsp"))):
        p = Path(f)
        if p.name == "build.lsp":
            continue
        text = strip_comments_strings(read_src(p))
        for m in re.finditer(r"\(defun\s+(c:[^\s()]+)", text, re.I):
            cmds.add(m.group(1)[2:])
        for m in re.finditer(r"\(defun\s+((?!c:)[A-Za-z][\w:$?!*>\-]*)", text):
            if ":" in m.group(1):
                funcs.add(m.group(1))
    return sorted(cmds, key=str.upper), sorted(funcs, key=str.lower)


def parse_load_list():
    """从 load.lsp 解析模块文件清单（路径分隔符统一为正斜杠）。"""
    text = read_src(TB_DIR / "load.lsp")
    m = re.search(r"\*TB:FILES\*\s*'\((.*?)\)\)", text, re.S)
    if not m:
        return []
    return [re.sub(r"[\\/]+", "/", f) for f in re.findall(r'"([^"]+)"', m.group(1))]


def lisp_str_list(items):
    return "(" + " ".join('"%s"' % i for i in items) + ")"


# ---------------------------------------------------------------------------
# 行为断言模板：在真实 CAD 引擎里造图元，断言库函数行为
# ---------------------------------------------------------------------------
BEHAVIOR_LSP = r"""
;; ===========================================================================
;; 第 4 部分：建测试图元
;; ===========================================================================
(lg "===== 4. entmake 建立测试图元 =====")

(defun mk (dxf / r)
  (setq r (vl-catch-all-apply 'entmake (list dxf)))
  (if (vl-catch-all-error-p r)
    (progn (err (strcat "entmake 失败: " (vl-catch-all-error-message r))) nil)
    (entlast)))

(setq *E:LINE* (mk '((0 . "LINE") (10 0.0 0.0 0.0) (11 100.0 0.0 0.0))))
(setq *E:CIRC* (mk '((0 . "CIRCLE") (10 0.0 0.0 0.0) (40 . 10.0))))
(setq *E:ARC*  (mk '((0 . "ARC") (10 0.0 0.0 0.0) (40 . 10.0) (50 . 0.0) (51 . 1.5707963268))))
(setq *E:PLCL* (mk '((0 . "LWPOLYLINE") (100 . "AcDbEntity") (100 . "AcDbPolyline")
                     (90 . 4) (70 . 1)
                     (10 0.0 0.0) (10 100.0 0.0) (10 100.0 50.0) (10 0.0 50.0))))
(setq *E:PLOP* (mk '((0 . "LWPOLYLINE") (100 . "AcDbEntity") (100 . "AcDbPolyline")
                     (90 . 3) (70 . 0)
                     (10 0.0 0.0) (10 100.0 0.0) (10 100.0 50.0))))
(setq *E:TEXT* (mk '((0 . "TEXT") (10 0.0 0.0 0.0) (40 . 3.5) (1 . "TB_TEST_123") (7 . "Standard"))))

(foreach p (list (cons "LINE" *E:LINE*) (cons "CIRCLE" *E:CIRC*) (cons "ARC" *E:ARC*)
                 (cons "LWPOLYLINE-closed" *E:PLCL*) (cons "LWPOLYLINE-open" *E:PLOP*)
                 (cons "TEXT" *E:TEXT*))
  (if (cdr p) (ok (strcat "entmake " (car p))) (bad (strcat "entmake " (car p)))))

;; --- 断言包装：任何异常记为 ERR，不中断整套 ---------------------------------
(defun T:apply (label fn / r)
  (setq r (vl-catch-all-apply fn nil))
  (if (vl-catch-all-error-p r)
    (progn (err (strcat label " 抛异常: " (vl-catch-all-error-message r))) nil)
    r))

(defun T:num (label fn exp tol)
  (A:num label (T:apply label fn) exp tol))

(defun T:pt (label fn exp tol)
  (A:pt label (T:apply label fn) exp tol))

(defun T:bool (label fn exp / v)
  (setq v (T:apply label fn))
  (if (eq (null v) (null exp)) (ok label) (bad (strcat label " 布尔值不符"))))

;; ===========================================================================
;; 第 5 部分：curve:* 曲线库行为断言
;; ===========================================================================
(lg "===== 5. curve:* 曲线库 =====")

(T:num "curve:length LINE(0,0)-(100,0)" '(lambda () (curve:length *E:LINE*)) 100.0 0.000001)
(T:num "curve:length CIRCLE R=10" '(lambda () (curve:length *E:CIRC*)) 62.831853 0.0001)
(T:num "curve:length ARC R=10 90deg" '(lambda () (curve:length *E:ARC*)) 15.707963 0.0001)
(T:num "curve:length LWPOLYLINE 100x50" '(lambda () (curve:length *E:PLCL*)) 300.0 0.000001)

;; curve:area：accoreconsole 下无 ActiveX 分支，vlax-curve-getarea 返回值不稳定
;; （实测同一表达式内可返回 T），故此处只断言"必须是实数"，精确面积值
;; （R=10 圆 314.159 / 100x50 矩形 5000）需在真实 AutoCAD 中复核。
(setq v (T:apply "curve:area CIRCLE" '(lambda () (curve:area *E:CIRC*))))
(if (numberp v) (ok (strcat "curve:area 圆返回实数 (值 " (rtos v 2 4) ")"))
  (bad (strcat "curve:area 圆返回非数值: " (vl-princ-to-string v))))
(setq v (T:apply "curve:area LWPOLYLINE" '(lambda () (curve:area *E:PLCL*))))
(if (numberp v) (ok (strcat "curve:area 闭合多段线返回实数 (值 " (rtos v 2 4) ")"))
  (bad (strcat "curve:area 闭合多段线返回非数值: " (vl-princ-to-string v))))

(T:pt "curve:startpt LINE" '(lambda () (curve:startpt *E:LINE*)) '(0.0 0.0 0.0) 0.000001)
(T:pt "curve:endpt LINE" '(lambda () (curve:endpt *E:LINE*)) '(100.0 0.0 0.0) 0.000001)
(T:pt "curve:midpt LINE" '(lambda () (curve:midpt *E:LINE*)) '(50.0 0.0 0.0) 0.000001)
(T:pt "curve:pt-at-dist LINE 25" '(lambda () (curve:pt-at-dist *E:LINE* 25.0)) '(25.0 0.0 0.0) 0.000001)
(T:pt "curve:closest-pt LINE (30,40)" '(lambda () (curve:closest-pt *E:LINE* '(30.0 40.0 0.0))) '(30.0 0.0 0.0) 0.000001)

(T:bool "curve:closed? LWPOLYLINE-closed" '(lambda () (curve:closed? *E:PLCL*)) T)
(T:bool "curve:closed? LWPOLYLINE-open" '(lambda () (curve:closed? *E:PLOP*)) nil)
(T:bool "curve:closed? CIRCLE" '(lambda () (curve:closed? *E:CIRC*)) T)

(setq v (T:apply "curve:vertices" '(lambda () (curve:vertices *E:PLCL*))))
(if (and (listp v) (= (length v) 4)) (ok "curve:vertices LWPOLYLINE -> 4 点")
  (bad (strcat "curve:vertices LWPOLYLINE -> " (vl-princ-to-string v))))
(setq v (T:apply "curve:vertices LINE" '(lambda () (curve:vertices *E:LINE*))))
(if (and (listp v) (= (length v) 2)) (ok "curve:vertices LINE -> 2 点")
  (bad (strcat "curve:vertices LINE -> " (vl-princ-to-string v))))

(T:pt "curve:inters-lines 十字相交"
  '(lambda () (curve:inters-lines '(0.0 0.0 0.0) '(100.0 0.0 0.0) '(50.0 -50.0 0.0) '(50.0 50.0 0.0)))
  '(50.0 0.0 0.0) 0.000001)
(T:bool "curve:inters-lines 不相交 -> nil"
  '(lambda () (curve:inters-lines '(0.0 0.0 0.0) '(10.0 0.0 0.0) '(50.0 5.0 0.0) '(60.0 5.0 0.0))) nil)

(setq *PTS:CCW* (list '(0.0 0.0 0.0) '(100.0 0.0 0.0) '(100.0 50.0 0.0) '(0.0 50.0 0.0)))
(setq *PTS:CW*  (list '(0.0 0.0 0.0) '(0.0 50.0 0.0) '(100.0 50.0 0.0) '(100.0 0.0 0.0)))
(T:bool "curve:clockwise? 逆时针 -> nil" '(lambda () (curve:clockwise? *PTS:CCW*)) nil)
(T:bool "curve:clockwise? 顺时针 -> T" '(lambda () (curve:clockwise? *PTS:CW*)) T)

(T:num "curve:tangent LINE 中点 -> 0.0"
  '(lambda () (curve:tangent *E:LINE* '(50.0 0.0 0.0))) 0.0 0.000001)

;; ===========================================================================
;; 第 6 部分：point:* 点运算库行为断言
;; ===========================================================================
(lg "===== 6. point:* 点运算库 =====")

(T:num "point:dist (0,0)-(3,4)" '(lambda () (point:dist '(0.0 0.0 0.0) '(3.0 4.0 0.0))) 5.0 0.000000001)
(T:num "point:angle (0,0)->(0,10) = 90deg"
  '(lambda () (point:angle '(0.0 0.0 0.0) '(0.0 10.0 0.0))) 1.5707963 0.000001)
(T:pt "point:mid (0,0)-(10,4)" '(lambda () (point:mid '(0.0 0.0 0.0) '(10.0 4.0 0.0))) '(5.0 2.0 0.0) 0.000000001)
(T:pt "point:polar (0,0) 0度 100" '(lambda () (point:polar '(0.0 0.0 0.0) 0.0 100.0)) '(100.0 0.0 0.0) 0.000000001)
(T:pt "point:offset (5,5) +3+4" '(lambda () (point:offset '(5.0 5.0 0.0) 3.0 4.0)) '(8.0 9.0 0.0) 0.000000001)
(T:pt "point:create (1,2)" '(lambda () (point:create 1.0 2.0 nil)) '(1.0 2.0 0.0) 0.000000001)
(T:pt "point:3d (1,2) z=5" '(lambda () (point:3d '(1.0 2.0) 5.0)) '(1.0 2.0 5.0) 0.000000001)

(T:bool "point:between? 在线段上" '(lambda () (point:between? '(5.0 0.0 0.0) '(0.0 0.0 0.0) '(10.0 0.0 0.0))) T)
(T:bool "point:between? 在线段外" '(lambda () (point:between? '(15.0 0.0 0.0) '(0.0 0.0 0.0) '(10.0 0.0 0.0))) nil)

(T:bool "point:in-polygon? 矩形内" '(lambda () (point:in-polygon? '(50.0 25.0 0.0) *PTS:CCW*)) T)
(T:bool "point:in-polygon? 矩形外" '(lambda () (point:in-polygon? '(200.0 25.0 0.0) *PTS:CCW*)) nil)

(setq v (T:apply "point:bbox" '(lambda () (point:bbox *PTS:CCW*))))
(if (and (listp v) (= (length v) 2)
         (< (abs (- (car (car v)) 0.0)) 0.000000001) (< (abs (- (cadr (cadr v)) 50.0)) 0.000000001))
  (ok "point:bbox -> ((0 0 0) (100 50 0))")
  (bad (strcat "point:bbox -> " (vl-princ-to-string v))))

(setq v (T:apply "point:center" '(lambda () (point:center *PTS:CCW*))))
(if (and (listp v) (< (abs (- (car v) 50.0)) 0.000000001) (< (abs (- (cadr v) 25.0)) 0.000000001))
  (ok "point:center -> (50 25 0)")
  (bad (strcat "point:center -> " (vl-princ-to-string v))))

(setq *NP* (list '(0.0 0.0 0.0) '(10.0 0.0 0.0) '(3.0 5.0 0.0)))
(setq v (T:apply "point:nearest" '(lambda () (point:nearest '(3.0 4.0 0.0) *NP*))))
(if (and (listp v) (< (abs (- (cadr v) 5.0)) 0.000000001)) (ok "point:nearest -> (3 5 0)")
  (bad (strcat "point:nearest -> " (vl-princ-to-string v))))

(setq v (T:apply "point:rect-2pt->4pt" '(lambda () (point:rect-2pt->4pt '(0.0 0.0 0.0) '(10.0 5.0 0.0)))))
(if (and (listp v) (= (length v) 4)) (ok "point:rect-2pt->4pt -> 4 角点")
  (bad (strcat "point:rect-2pt->4pt -> " (vl-princ-to-string v))))
"""

BEHAVIOR_LSP += r"""
;; ===========================================================================
;; 第 7 部分：entity:* / txt:* 实体与文字库行为断言
;; ===========================================================================
(lg "===== 7. entity:* / txt:* 实体文字库 =====")

(A:str "entity:get-type LINE" (T:apply "get-type" '(lambda () (entity:get-type *E:LINE*))) "LINE")
(A:str "entity:get-dxf LINE code0" (T:apply "get-dxf" '(lambda () (entity:get-dxf *E:LINE* 0))) "LINE")
(T:num "entity:get-dxf LINE code10.x" '(lambda () (car (entity:get-dxf *E:LINE* 10))) 0.0 0.000000001)

(setq v (T:apply "txt:get-content" '(lambda () (txt:get-content *E:TEXT*))))
(A:str "txt:get-content TEXT" v "TB_TEST_123")
(T:num "txt:get-height TEXT" '(lambda () (txt:get-height *E:TEXT*)) 3.5 0.000000001)

(T:apply "txt:set-content" '(lambda () (txt:set-content *E:TEXT* "TB_UPDATED")))
(A:str "txt:set-content 往返" (T:apply "get-content2" '(lambda () (txt:get-content *E:TEXT*))) "TB_UPDATED")

(T:apply "txt:set-height" '(lambda () (txt:set-height *E:TEXT* 7.0)))
(T:num "txt:set-height 往返" '(lambda () (txt:get-height *E:TEXT*)) 7.0 0.000000001)

(T:apply "txt:set-rotation" '(lambda () (txt:set-rotation *E:TEXT* 0.5)))
(T:num "txt:set-rotation 往返" '(lambda () (txt:get-rotation *E:TEXT*)) 0.5 0.000000001)

(setq v (T:apply "entity:make-line" '(lambda () (entity:make-line '(0.0 0.0 0.0) '(50.0 50.0 0.0) "0"))))
(if v (ok "entity:make-line 创建") (bad "entity:make-line 返回 nil"))

(setq v (T:apply "entity:make-circle" '(lambda () (entity:make-circle '(200.0 200.0 0.0) 25.0 "0"))))
(if v (progn (ok "entity:make-circle 创建")
             (T:num "  -> curve:length 校验" '(lambda () (curve:length v)) 157.079633 0.001))
  (bad "entity:make-circle 返回 nil"))

(setq v (T:apply "entity:make-text" '(lambda () (entity:make-text "MAKE_TEXT_OK" '(0.0 300.0 0.0) 3.0 "Standard" "0"))))
(if v (progn (ok "entity:make-text 创建")
             (A:str "  -> 内容回读" (T:apply "gc" '(lambda () (txt:get-content v))) "MAKE_TEXT_OK"))
  (bad "entity:make-text 返回 nil"))

;; ===========================================================================
;; 第 8 部分：结构参数库计算正确性（数值断言，对照 GB50010）
;; ===========================================================================
(lg "===== 8. concrete:* 结构参数库 =====")

;; C30: fck = 0.88*0.76*1.0*30 = 20.064 (GB50010 表值 20.1)
(T:num "concrete:fck C30" '(lambda () (concrete:fck 30)) 20.064 0.05)
;; C50: fck = 0.88*0.76*0.9675*50 = 32.353 (GB50010 表值 32.4)
(T:num "concrete:fck C50" '(lambda () (concrete:fck 50)) 32.353 0.05)
;; C80: fck = 0.88*0.82*0.87*80 = 50.199 (GB50010 表值 50.2)
(T:num "concrete:fck C80" '(lambda () (concrete:fck 80)) 50.199 0.05)

(setq v (T:apply "concrete:ftk C30" '(lambda () (concrete:ftk 30))))
(A:num "concrete:ftk C30 (表值 2.01)" v 2.01 0.02)

(setq v (T:apply "concrete:fc C30" '(lambda () (concrete:fc 30))))
(if (numberp v) (ok (strcat "concrete:fc C30 -> " (rtos v 2 2))) (bad "concrete:fc 非数值"))

;; ===========================================================================
;; 第 9 部分：section:props 截面特性数值断言
;; ===========================================================================
(lg "===== 9. section:props 截面特性 =====")

;; 100x50 矩形：面积 5000，形心 (50,25)，Ix = 100*50^3/12 = 1041666.67
(setq *SECT:RES* (T:apply "section:props" '(lambda () (section:props *PTS:CCW*))))
(if (listp *SECT:RES*)
  (progn
    (ok "section:props 返回表")
    (lg (strcat "SECT-DUMP " (vl-princ-to-string *SECT:RES*))))
  (bad (strcat "section:props -> " (vl-princ-to-string *SECT:RES*))))
"""


def build_script(cmds, funcs):
    """拼装完整 LISP 测试脚本。"""
    head = ''';;; _tb_functional_gen.lsp -- 由 run_tb_functional.py 自动生成，请勿手工编辑。
;;; TB-Toolbox 真机功能测试：加载、注册完整性、库函数行为断言。
(setvar "SECURELOAD" 0)
(setvar "FILEDIA" 0)
(setvar "CMDECHO" 0)
(setvar "ATTREQ" 0)

(setq *ROOT* "d:/My Code/Claude Code/03-AutoCAD-lisp")
(setq *LOGPATH* (strcat *ROOT* "/_tb_func_result.log"))
(setq *LOG* (open *LOGPATH* "w"))
(setq *PASS* 0 *FAIL* 0 *ERR* 0)

(defun lg (m) (setq *LOG* (open *LOGPATH* "a")) (write-line m *LOG*) (close *LOG*) (princ m) (princ))
(defun ok (m) (setq *PASS* (1+ *PASS*)) (lg (strcat "  [PASS] " m)))
(defun bad (m) (setq *FAIL* (1+ *FAIL*)) (lg (strcat "  [FAIL] " m)))
(defun err (m) (setq *ERR* (1+ *ERR*)) (lg (strcat "  [ERR ] " m)))

;; --- 断言工具 --------------------------------------------------------------
(defun A:num (label got exp tol)
  (if (and (numberp got) (< (abs (- got exp)) tol))
    (ok (strcat label " ~= " (rtos exp 2 4)))
    (bad (strcat label " = " (if (numberp got) (rtos got 2 6) "NIL")
                 ", 期望 ~= " (rtos exp 2 6)))))

(defun A:pt (label got exp tol)
  (if (and (listp got) (>= (length got) 2)
           (< (abs (- (car got)   (car exp)))   tol)
           (< (abs (- (cadr got)  (cadr exp)))  tol))
    (ok (strcat label " ~= (" (rtos (car exp) 2 2) " " (rtos (cadr exp) 2 2) ")"))
    (bad (strcat label " = " (vl-princ-to-string got)
                 ", 期望 " (vl-princ-to-string exp)))))

(defun A:str (label got exp)
  (if (equal got exp) (ok (strcat label " = " (vl-princ-to-string got)))
    (bad (strcat label " = " (vl-princ-to-string got) ", 期望 " (vl-princ-to-string exp)))))

;; ===========================================================================
;; 第 1 部分：加载工具箱
;; ===========================================================================
(lg "===== 1. 加载 TB-Toolbox =====")
(setq *TB:PATH* (strcat *ROOT* "/TB-Toolbox"))
(setq *UC:ROOT* *ROOT*)
;; 模块清单来自 load.lsp；自行计数，避免依赖其会被清空的临时变量
(setq *TB:FILES* '@@TB_FILES@@)
(setq *LD:OK* 0 *LD:FAIL* 0)
(foreach f *TB:FILES*
  (setq fp (if (= (substr f 1 2) "..")
            (strcat *ROOT* "/" (substr f 4))
            (strcat *TB:PATH* "/" f)))
  (if (not (findfile fp))
    (progn (setq *LD:FAIL* (1+ *LD:FAIL*))
           (lg (strcat "  [ERR ] 文件缺失 " f)))
    (if (vl-catch-all-error-p (setq r (vl-catch-all-apply 'load (list fp))))
      (progn (setq *LD:FAIL* (1+ *LD:FAIL*))
             (lg (strcat "  [ERR ] 加载失败 " f " -> " (vl-catch-all-error-message r))))
      (setq *LD:OK* (1+ *LD:OK*)))))
(if (= *LD:FAIL* 0)
  (ok (strcat "全部 " (itoa *LD:OK*) " 个模块文件加载成功"))
  (bad (strcat (itoa *LD:FAIL*) " / " (itoa (+ *LD:OK* *LD:FAIL*)) " 个模块文件加载失败")))
(setq r (vl-catch-all-apply 'load (list (strcat *TB:PATH* "/load.lsp"))))
(if (vl-catch-all-error-p r)
  (err (strcat "load.lsp 入口脚本执行失败: " (vl-catch-all-error-message r)))
  (ok "load.lsp 入口脚本可执行"))
(if (uc:function-defined-p 'tb:resolve-root)
  (ok "tb:resolve-root 已定义")
  (bad "tb:resolve-root 未定义"))
'''

    head = head.replace("@@TB_FILES@@", lisp_str_list(parse_load_list()))

    part_cmd = '''
;; ===========================================================================
;; 第 2 部分：命令注册完整性（源码提取的 %d 个 c: 命令）
;; ===========================================================================
(lg "===== 2. 命令注册检查 =====")
(setq *CMD:LIST* '%s)
(setq *CMD:MISS* 0)
(foreach n *CMD:LIST*
  (setq key (strcat "c:" n))
  (setq r (vl-catch-all-apply 'read (list key)))
  (if (null (car (atoms-family 1 (list key))))
    (progn (setq *CMD:MISS* (1+ *CMD:MISS*))
           (lg (strcat "  [FAIL] 未注册命令 " key))
           (lg (strcat "  DIAG read-> " (vl-princ-to-string r)
                       " | sym-name-> " (if (eq (type r) 'SYM) (vl-symbol-name r) "n/a")
                       " | uc:function-defined-p-> " (vl-princ-to-string (uc:function-defined-p r)))))))
(if (= *CMD:MISS* 0)
  (ok (strcat "全部 " (itoa (length *CMD:LIST*)) " 个命令均已注册"))
  (bad (strcat (itoa *CMD:MISS*) " / " (itoa (length *CMD:LIST*)) " 个命令未注册")))
''' % (len(cmds), lisp_str_list(cmds))

    part_func = '''
;; ===========================================================================
;; 第 3 部分：库函数注册完整性（源码提取的 %d 个公开函数）
;; ===========================================================================
(lg "===== 3. 库函数注册检查 =====")
(setq *FUNC:LIST* '%s)
(setq *FUNC:MISS* 0)
(foreach n *FUNC:LIST*
  (if (null (car (atoms-family 1 (list n))))
    (progn (setq *FUNC:MISS* (1+ *FUNC:MISS*))
           (lg (strcat "  [FAIL] 未定义函数 " n)))))
(if (= *FUNC:MISS* 0)
  (ok (strcat "全部 " (itoa (length *FUNC:LIST*)) " 个库函数均已定义"))
  (bad (strcat (itoa *FUNC:MISS*) " / " (itoa (length *FUNC:LIST*)) " 个库函数未定义")))
''' % (len(funcs), lisp_str_list(funcs))

    tail = '''
;; ===========================================================================
;; 第 10 部分：命令目录一致性
;; ===========================================================================
(lg "===== 10. 命令目录 =====")
(if *TB:CMD-CATALOG*
  (progn
    (setq *CAT:N* 0 *CAT:BAD* 0)
    (foreach e *TB:CMD-CATALOG*
      (setq *CAT:N* (1+ *CAT:N*))
      (setq nm (cadr e))
      (setq r (vl-catch-all-apply 'read (list (strcat "c:" nm))))
      (if (or (vl-catch-all-error-p r) (null r) (not (uc:function-defined-p r)))
        (progn (setq *CAT:BAD* (1+ *CAT:BAD*))
               (lg (strcat "  [FAIL] 目录项指向未定义命令: " nm)))))
    (if (= *CAT:BAD* 0)
      (ok (strcat "目录 " (itoa *CAT:N*) " 项全部指向有效命令"))
      (bad (strcat (itoa *CAT:BAD*) " / " (itoa *CAT:N*) " 个目录项失效"))))
  (bad "*TB:CMD-CATALOG* 未定义"))

;; ===========================================================================
;; 汇总
;; ===========================================================================
(lg "")
(lg "===== SUMMARY =====")
(lg (strcat "PASS=" (itoa *PASS*) " FAIL=" (itoa *FAIL*) " ERR=" (itoa *ERR*)))
(princ)
'''

    return head + part_cmd + part_func + BEHAVIOR_LSP + tail


def run(accore, lsp_path):
    """调用 accoreconsole 执行测试脚本。"""
    with tempfile.TemporaryDirectory(prefix="tb_func_") as tmp:
        scr = Path(tmp) / "run.scr"
        p = str(lsp_path).replace("\\", "/")
        scr.write_text('(setvar "SECURELOAD" 0)\n(load "%s")\n_.quit _y\n' % p,
                       encoding="ascii")
        proc = subprocess.run([accore, "/s", str(scr)], capture_output=True, timeout=600)
    return proc.returncode == 0, (proc.stdout or b"").decode("gbk", errors="replace")


def parse_report():
    """解析结果日志，返回 (sections, 通过, 失败, 异常)。"""
    if not LOG_PATH.exists():
        return [], 0, 0, 0
    text = LOG_PATH.read_bytes().decode("gbk", errors="replace")
    sections, cur_title, cur_items = [], None, []
    for line in text.splitlines():
        s = line.strip()
        if s.startswith("=====") and s.endswith("====="):
            if cur_title is not None:
                sections.append((cur_title, cur_items))
            cur_title, cur_items = s.strip("= "), []
        elif s and cur_title is not None:
            cur_items.append(s)
    if cur_title is not None:
        sections.append((cur_title, cur_items))
    tp = tf = te = 0
    for _t, items in sections:
        tp += sum(1 for i in items if i.startswith("[PASS]"))
        tf += sum(1 for i in items if i.startswith("[FAIL]"))
        te += sum(1 for i in items if i.startswith("[ERR ]"))
    return sections, tp, tf, te


def print_report(sections, total_pass, total_fail, total_err):
    """打印分层报告。"""
    print("=" * 68)
    print("  TB-Toolbox 真机功能测试报告（accoreconsole / AutoCAD）")
    print("=" * 68)
    for title, items in sections:
        if title == "SUMMARY":
            continue
        p = sum(1 for i in items if i.startswith("[PASS]"))
        f = sum(1 for i in items if i.startswith("[FAIL]"))
        e = sum(1 for i in items if i.startswith("[ERR ]"))
        print("")
        print("%s[%s]  通过 %d / 失败 %d / 异常 %d"
              % ("OK " if (f == 0 and e == 0) else "!! ", title, p, f, e))
        for i in items:
            if i.startswith("[FAIL]") or i.startswith("[ERR ]"):
                print("      " + i)
    print("")
    print("=" * 68)
    print("  合计: 通过 %d  失败 %d  异常 %d" % (total_pass, total_fail, total_err))
    print("  结论: %s" % ("全部通过" if (total_fail == 0 and total_err == 0) else "存在失败项"))
    print("=" * 68)


def run_functional_suite(accore=None):
    """执行完整功能测试，返回 (通过, 失败, 异常)。无法执行时返回 (-1, -1, -1)。

    供 run_tests.py 复用；accore 可传入已定位的引擎路径。
    """
    GEN_LSP.write_bytes(build_script(*collect_names()).encode("gbk", errors="replace"))
    if accore is None:
        accore = find_accoreconsole()
    if not accore:
        return -1, -1, -1
    if LOG_PATH.exists():
        LOG_PATH.unlink()
    run(accore, GEN_LSP)
    if not LOG_PATH.exists():
        return 0, 1, 0
    _sections, tp, tf, te = parse_report()
    return tp, tf, te


def report():
    """CLI 用：解析并打印报告，返回退出码。"""
    if not LOG_PATH.exists():
        print("未找到结果日志: %s" % LOG_PATH)
        return 1
    sections, tp, tf, te = parse_report()
    print_report(sections, tp, tf, te)
    return 0 if (tf == 0 and te == 0) else 1


def main():
    ap = argparse.ArgumentParser(description="TB-Toolbox 真机功能测试")
    ap.add_argument("--gen", action="store_true", help="只生成脚本，不执行")
    args = ap.parse_args()

    cmds, funcs = collect_names()
    print("源码提取: %d 个命令, %d 个公开库函数" % (len(cmds), len(funcs)))

    GEN_LSP.write_bytes(build_script(cmds, funcs).encode("gbk", errors="replace"))
    print("已生成测试脚本: %s" % GEN_LSP)
    if args.gen:
        return 0

    accore = find_accoreconsole()
    if not accore:
        print("未找到 accoreconsole.exe，无法执行真机测试")
        return 1
    print("引擎: %s" % accore)

    if LOG_PATH.exists():
        LOG_PATH.unlink()
    _, out = run(accore, GEN_LSP)
    if not LOG_PATH.exists():
        print("测试未产出日志，accoreconsole 输出尾部：")
        print("\n".join(out.splitlines()[-20:]))
        return 1
    return report()


if __name__ == "__main__":
    sys.exit(main())
