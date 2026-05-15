编程 Hooks 完整指南（带详细注释版）
📚 一、React Hooks 详解
1.1 核心 Hooks
useState - 状态管理 Hook

```python
// 用法：声明组件内的状态变量
const [count, setCount] = useState(0)

// 注释说明：
// count  - 当前状态值
// setCount - 更新状态的函数，调用后会触发组件重新渲染
// 0 - 初始状态值，可以是任何类型（数字、字符串、对象、数组等）

// 使用场景：
// ✅ 表单输入框的值
// ✅ 按钮点击计数
// ✅ 模态框显示/隐藏状态
// ✅ 标签页切换状态

```



useEffect - 副作用 Hook

```python
// 用法：处理组件挂载、更新、卸载等副作用
useEffect(() => {
  // 组件挂载后执行
  console.log('组件已挂载')

  // 返回清理函数，组件卸载时执行
  return () => {
    console.log('组件已卸载')
  }
}, []) // 依赖数组为空，只在挂载时执行一次

// 注释说明：
// 依赖数组决定 effect 何时重新执行：
// [] - 只在组件挂载时执行一次
// [count] - 当 count 变化时重新执行
// 省略数组 - 每次渲染都执行（慎用）

// 常见使用场景：
// ✅ 数据获取（API 调用）
// ✅ 订阅事件（WebSocket、resize 等）
// ✅ 手动操作 DOM
// ✅ 设置定时器
// ✅ 日志记录

```



useContext - 上下文 Hook



```python
// 用法：从 Context 对象中读取值
const theme = useContext(ThemeContext)

// 注释说明：
// ThemeContext - 通过 createContext() 创建的上下文对象
// 当 Context 的值变化时，使用该 Hook 的组件会重新渲染

// 使用场景：
// ✅ 全局主题切换（浅色/深色模式）
// ✅ 用户认证状态
// ✅ 语言国际化配置
// ✅ 全局配置信息传递

```









useReducer - 复杂状态管理

```python
// 用法：替代 useState，处理复杂的状态逻辑
const [state, dispatch] = useReducer(reducer, initialState)

// reducer 函数定义
function reducer(state, action) {
  switch (action.type) {
    case 'increment':
      return { count: state.count + 1 }
    case 'decrement':
      return { count: state.count - 1 }
    default:
      return state
  }
}

// 注释说明：
// state - 当前状态对象
// dispatch - 分发 actions 的函数
// initialState - 初始状态
// action.type - 动作类型
// action.payload - 动作携带的数据

// 使用场景：
// ✅ 复杂表单状态管理
// ✅ 状态机逻辑
// ✅ 购物车状态
// ✅ 多步骤向导状态

```





useMemo - 性能优化 Hook

```python
// 用法：缓存计算结果，避免重复计算
const memoizedValue = useMemo(() => computeExpensiveValue(a, b), [a, b])

// 注释说明：
// 第一个参数 - 计算函数
// 第二个参数 - 依赖数组，只有依赖变化时才重新计算
// 返回值 - 缓存的计算结果

// 使用场景：
// ✅ 大数据列表排序/过滤
// ✅ 复杂数学计算
// ✅ 对象/数组转换
// ✅ 避免重复渲染子组件

```





useCallback - 函数引用缓存

```python
// 用法：缓存函数引用，避免重新创建
const memoizedCallback = useCallback(() => {
  doSomething(a, b)
}, [a, b])

// 注释说明：
// 第一个参数 - 要缓存的函数
// 第二个参数 - 依赖数组
// 只有当依赖变化时，函数引用才会更新

// 使用场景：
// ✅ 传递给子组件的 props 函数
// ✅ 作为其他 Hook 的依赖项
// ✅ 事件处理函数

```





useRef - 持久引用 Hook

```python
// 用法：创建可变引用，不触发重新渲染
const inputRef = useRef(null)

// 注释说明：
// useRef.current - 存储值的位置
// 修改 current 不会触发组件重新渲染
// 可以在组件生命周期中持久保存值

// 常见用法：
// ✅ DOM 元素引用（访问 input、div 等）
// ✅ 存储不需要触发渲染的值（定时器 ID、上一次的值）
// ✅ 保存函数或状态，避免闭包问题

```









## 🎯 二、React Router Hooks

```python
// 使用路由时需要先安装 react-router-dom

// useNavigate - 编程式导航
const navigate = useNavigate()
navigate('/home')                    // 跳转到首页
navigate(-1)                         // 后退一页
navigate('/home', { state: { key: 'value' } })  // 带状态跳转

// useParams - 获取 URL 路径参数
const { id } = useParams()
// URL: /users/123 => id = '123'

// useSearchParams - 获取 URL 查询参数
const [searchParams, setSearchParams] = useSearchParams()
searchParams.get('page')             // 获取 page 参数值
setSearchParams({ page: 1 })         // 更新查询参数

// useLocation - 获取当前路由信息
const location = useLocation()
location.pathname                    // 当前路径
location.state                       // 路由状态

// useRouteMatch - 匹配当前路由模式
const match = useRouteMatch()
match.params                         // URL 参数
match.path                           // 匹配的路径模式

```







## 📂 三、文件操作 Hooks

### 3.1 文件监听系统

```python
// chokidar 是 Node.js 文件监听库，常用于构建工具、热更新

const chokidar = require('chokidar')

// 初始化监听器
const watcher = chokidar.watch('src/**/*', {
  ignored: /node_modules/,     // 排除 node_modules
  persistent: true,            // 保持监听
  followSymlinks: true,        // 跟随符号链接
  usePolling: false            // 不使用轮询（性能更好）
})

// 监听文件变化事件
watcher
  .on('add', (path) => {
    console.log(`${path} 文件已创建`)
    // 触发热更新、重新编译
  })
  .on('change', (path) => {
    console.log(`${path} 文件已修改`)
    // 重新编译代码
  })
  .on('unlink', (path) => {
    console.log(`${path} 文件已删除`)
    // 清理相关资源
  })
  .on('error', (error) => {
    console.error(`监听错误：${error}`)
  })

// 停止监听
watcher.close()

```







## 🔔 四、事件处理 Hooks

### 4.1 订阅 - 发布模式

```python
// 自定义事件系统，实现模块间解耦通信

class EventEmitter {
  constructor() {
    this.events = {}  // 存储所有事件
  }

  // 订阅事件
  on(event, callback) {
    if (!this.events[event]) {
      this.events[event] = []
    }
    this.events[event].push(callback)
    return () => this.off(event, callback)  // 返回取消订阅函数
  }

  // 取消订阅
  off(event, callback) {
    if (!this.events[event]) return
    this.events[event] = this.events[event].filter(
      cb => cb !== callback
    )
  }

  // 触发事件
  emit(event, data) {
    if (!this.events[event]) return
    this.events[event].forEach(cb => cb(data))
  }

  // 一次性订阅（触发后自动取消）
  once(event, callback) {
    const wrapper = (...args) => {
      callback(...args)
      this.off(event, wrapper)
    }
    this.on(event, wrapper)
  }
}

// 使用示例
const emitter = new EventEmitter()
emitter.on('dataReady', (data) => console.log('数据准备好了', data))
emitter.emit('dataReady', { id: 1, name: 'test' })

```



### 4.2 生命周期事件

```python
// 组件生命周期事件钩子

const lifeCycleHooks = {
  beforeMount: [],   // 挂载前钩子（可修改 DOM，阻止挂载）
  mounted: [],       // 挂载后钩子（DOM 已渲染）
  beforeUpdate: [],  // 更新前钩子（可修改状态）
  updated: [],       // 更新后钩子（DOM 已更新）
  beforeUnmount: [], // 卸载前钩子（清理资源）
  unmounted: []      // 卸载后钩子（组件已移除）
}

// 注册钩子
function registerHook(hookName, callback) {
  lifeCycleHooks[hookName].push(callback)
}

// 执行钩子
function runHooks(hookName, data) {
  lifeCycleHooks[hookName].forEach(cb => cb(data))
}

```









## 🌐 五、网络请求 Hooks

### 5.1 Fetch/AJAX

```python
// 封装的网络请求 Hook，统一错误处理和加载状态

function useFetch(url) {
  const [data, setData] = useState(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState(null)

  useEffect(() => {
    const controller = new AbortController()  // 请求取消控制器

    const fetchData = async () => {
      try {
        const response = await fetch(url, {
          signal: controller.signal  // 支持取消请求
        })
        const result = await response.json()
        setData(result)
      } catch (err) {
        if (err.name !== 'AbortError') {
          setError(err.message)
        }
      } finally {
        setLoading(false)
      }
    }

    fetchData()

    return () => controller.abort()  // 组件卸载时取消请求
  }, [url])

  return { data, loading, error }
}

```





### 5.2 WebSocket

```python
// WebSocket 连接管理 Hook

function useWebSocket(url, options = {}) {
  const [socket, setSocket] = useState(null)
  const [messages, setMessages] = useState([])
  const [status, setStatus] = useState('disconnected')

  useEffect(() => {
    const ws = new WebSocket(url)
    
    ws.onopen = () => setStatus('connected')
    ws.onmessage = (event) => {
      setMessages(prev => [...prev, JSON.parse(event.data)])
    }
    ws.onclose = () => setStatus('disconnected')
    ws.onerror = (error) => setStatus('error')

    setSocket(ws)

    return () => ws.close()  // 清理连接
  }, [url])

  // 发送消息的方法
  const sendMessage = (data) => {
    if (socket && socket.readyState === WebSocket.OPEN) {
      socket.send(JSON.stringify(data))
    }
  }

  return { socket, messages, status, sendMessage }
}

```









## 📝 六、表单处理 Hooks

### 6.1 表单验证 Hook

```python
// 完整的表单验证 Hook

function useForm(initialValues, validate) {
  const [values, setValues] = useState(initialValues)
  const [errors, setErrors] = useState({})
  const [touched, setTouched] = useState({})
  const [isSubmitting, setIsSubmitting] = useState(false)

  // 处理字段变化
  const handleChange = (e) => {
    const { name, value, type, checked } = e.target
    setValues(prev => ({
      ...prev,
      [name]: type === 'checkbox' ? checked : value
    }))
  }

  // 处理字段失焦
  const handleBlur = (e) => {
    const { name } = e.target
    setTouched(prev => ({ ...prev, [name]: true }))
  }

  // 提交处理
  const handleSubmit = async (e) => {
    e.preventDefault()
    setIsSubmitting(true)
    
    const validationErrors = validate(values)
    setErrors(validationErrors)

    if (Object.keys(validationErrors).length === 0) {
      // 验证通过，提交数据
      await onSubmit(values)
    }

    setIsSubmitting(false)
  }

  return {
    values,
    errors,
    touched,
    isSubmitting,
    handleChange,
    handleBlur,
    handleSubmit,
    resetForm: () => {
      setValues(initialValues)
      setErrors({})
      setTouched({})
    }
  }
}

```





## ⚡ 七、性能优化 Hooks

### 7.1 防抖 Hook

```python
// 防抖：多次调用合并为一次，适用于输入框、搜索框

function useDebounce(callback, delay) {
  const timerRef = useRef(null)

  useEffect(() => {
    return () => {
      if (timerRef.current) {
        clearTimeout(timerRef.current)
      }
    }
  }, [])

  const debounced = useCallback((...args) => {
    if (timerRef.current) {
      clearTimeout(timerRef.current)
    }
    timerRef.current = setTimeout(() => {
      callback(...args)
      timerRef.current = null
    }, delay)
  }, [callback, delay])

  return debounced
}

// 使用示例
const debouncedSearch = useDebounce((query) => {
  console.log('搜索：', query)  // 停止输入 300ms 后才执行
}, 300)

```







### 7.2 节流 Hook

```python
// 节流：固定时间内只执行一次，适用于滚动、窗口调整

function useThrottle(callback, delay) {
  const lastCallTime = useRef(0)

  const throttled = useCallback((...args) => {
    const now = Date.now()
    if (now - lastCallTime.current >= delay) {
      lastCallTime.current = now
      callback(...args)
    }
  }, [callback, delay])

  return throttled
}

// 使用示例
const throttledResize = useThrottle(() => {
  console.log('窗口大小变化')
}, 1000)

```







### 7.3 懒加载 Hook

```python
// 元素进入视口时触发，适用于图片懒加载、无限滚动

function useInView(options = {}) {
  const [isInView, setIsInView] = useState(false)
  const ref = useRef(null)

  useEffect(() => {
    const element = ref.current
    if (!element) return

    const observer = new IntersectionObserver(
      ([entry]) => {
        setIsInView(entry.isIntersecting)
      },
      options
    )

    observer.observe(element)
    return () => observer.disconnect()
  }, [options])

  return [ref, isInView]
}

// 使用示例
const [ref, isVisible] = useInView({ threshold: 0.1 })
// isVisible 为 true 时元素进入视口

```









## 🧪 八、测试框架 Hooks

### 8.1 Jest/Mocha

```python
// 测试生命周期 Hook

describe('用户模块', () => {
  // beforeAll - 所有测试开始前执行（只执行一次）
  beforeAll(() => {
    console.log('测试套件初始化')
  })

  // beforeEach - 每个测试前执行
  beforeEach(() => {
    console.log('每个测试前的准备工作')
  })

  test('用户登录成功', () => {
    expect(true).toBe(true)
  })

  test('用户登录失败', () => {
    expect(false).toBe(false)
  })

  // afterEach - 每个测试后执行
  afterEach(() => {
    console.log('每个测试后的清理工作')
  })

  // afterAll - 所有测试结束后执行（只执行一次）
  afterAll(() => {
    console.log('测试套件结束')
  })
})

```







## 💾 九、状态管理 Hooks

### 9.1 Redux Toolkit

```python
// 使用 Redux Toolkit 的标准 Hooks

import { useSelector, useDispatch } from 'react-redux'

// useSelector - 选择状态切片
const count = useSelector((state) => state.count)

// useDispatch - 获取 dispatch 函数
const dispatch = useDispatch()

// 提交 action
dispatch({ type: 'INCREMENT' })

// 封装的增删改查操作
const increment = () => dispatch({ type: 'INCREMENT' })
const decrement = () => dispatch({ type: 'DECREMENT' })

```









### 9.2 Zustand

```python
// Zustand 轻量级状态管理库

import create from 'zustand'

const useStore = create((set) => ({
  count: 0,
  setName: (name) => set({ name }),
  increment: () => set((state) => ({ count: state.count + 1 }))
}))

// 使用组件内
function Counter() {
  const count = useStore((state) => state.count)
  const increment = useStore((state) => state.increment)

  return (
    <button onClick={increment}>
      当前值：{count}
    </button>
  )
}

```









## 📡 十、数据获取 Hooks

### 10.1 React Query

```python
// React Query - 服务器状态管理

import { useQuery, useMutation, useInfiniteQuery } from '@tanstack/react-query'

// 数据获取 Hook
const { data, isLoading, error, refetch } = useQuery({
  queryKey: ['users'],
  queryFn: () => fetch('/api/users').then(res => res.json())
})

// 数据修改 Hook
const { mutate, isLoading } = useMutation({
  mutationFn: (data) => fetch('/api/users', {
    method: 'POST',
    body: JSON.stringify(data)
  }),
  onSuccess: () => refetch()  // 修改后刷新数据
})

// 分页数据 Hook
const { data, hasNextPage, fetchNextPage } = useInfiniteQuery({
  queryKey: ['posts'],
  queryFn: ({ pageParam }) => fetch(`/api/posts?page=${pageParam}`),
  initialPageParam: 1,
  getNextPageParam: (lastPage) => lastPage.hasNextPage ? lastPage.page + 1 : undefined
})

```







### 10.2 SWR



```python
// SWR - 轻量级数据获取库

import useSWR from 'swr'

// 基础数据获取
const { data, error, mutate } = useSWR('/api/data', fetcher)

// 自动重新验证
const { data, isValidating } = useSWR('/api/data', fetcher, {
  revalidateOnFocus: true,
  revalidateOnReconnect: true
})

// 批量数据获取
const { data: posts } = useSWR('/api/posts')
const { data: comments } = useSWR('/api/comments')

```







## 🎨 十一、实用自定义 Hook 示例

### 11.1 本地存储 Hook

```python
function useLocalStorage(key, initialValue) {
  // 初始状态
  const [storedValue, setStoredValue] = useState(() => {
    try {
      const item = localStorage.getItem(key)
      return item ? JSON.parse(item) : initialValue
    } catch (error) {
      console.error('读取 localStorage 失败:', error)
      return initialValue
    }
  })

  // 更新状态时同步 localStorage
  useEffect(() => {
    try {
      localStorage.setItem(key, JSON.stringify(storedValue))
    } catch (error) {
      console.error('写入 localStorage 失败:', error)
    }
  }, [key, storedValue])

  // 返回状态和更新函数
  return [storedValue, setStoredValue]
}

// 使用示例
const [theme, setTheme] = useLocalStorage('theme', 'light')

```







### 11.2 鼠标位置 Hook

```python
function useMousePosition() {
  const [position, setPosition] = useState({ x: 0, y: 0 })

  useEffect(() => {
    const handleMouseMove = (e) => {
      setPosition({ x: e.clientX, y: e.clientY })
    }

    window.addEventListener('mousemove', handleMouseMove)
    
    // 组件卸载时移除监听
    return () => window.removeEventListener('mousemove', handleMouseMove)
  }, [])

  return position
}

// 使用示例
const { x, y } = useMousePosition()

```





### 11.3 窗口大小 Hook

```python
function useWindowSize() {
  const [size, setSize] = useState({
    width: window.innerWidth,
    height: window.innerHeight
  })

  useEffect(() => {
    const handleResize = () => {
      setSize({
        width: window.innerWidth,
        height: window.innerHeight
      })
    }

    window.addEventListener('resize', handleResize)
    return () => window.removeEventListener('resize', handleResize)
  }, [])

  return size
}

```







## 📋 十二、使用优先级总结

| 优先级 | Hook        | 使用场景           | 推荐程度 |
| ------ | ----------- | ------------------ | -------- |
| ⭐⭐⭐⭐⭐  | useState    | 几乎所有组件都需要 | 必备     |
| ⭐⭐⭐⭐⭐  | useEffect   | 副作用处理         | 必备     |
| ⭐⭐⭐⭐   | useRef      | DOM 操作、持久值   | 强烈推荐 |
| ⭐⭐⭐⭐   | useMemo     | 性能优化           | 推荐     |
| ⭐⭐⭐⭐   | useCallback | 函数缓存           | 推荐     |
| ⭐⭐⭐    | useContext  | 全局状态传递       | 视需求   |
| ⭐⭐⭐    | 防抖/节流   | 性能优化           | 推荐     |
| ⭐⭐⭐    | 网络请求    | 数据获取           | 推荐     |
| ⭐⭐     | 自定义 Hook | 代码复用           | 灵活使用 |
| ⭐⭐     | 状态管理    | 复杂应用           | 视需求   |

------

## 💡 最佳实践提示

1. **优先使用内置 Hook**，避免重复造轮子
2. **自定义 Hook 以 `use` 开头**，符合 React 命名规范
3. **依赖数组要完整**，避免闭包陷阱
4. **清理函数必须写**，防止内存泄漏
5. **组合 Hook**，将复杂逻辑抽象为可复用 Hook
6. **类型安全**，使用 TypeScript 定义 Hook 类型









