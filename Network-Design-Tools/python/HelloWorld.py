import ctypes
msg = "Hello World!"
ctypes.windll.user32.MessageBoxW(0, msg, "TEST POP UP", 1)
print(msg)