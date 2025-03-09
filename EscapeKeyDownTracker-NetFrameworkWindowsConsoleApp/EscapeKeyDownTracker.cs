//https://learn.microsoft.com/en-us/archive/blogs/toub/low-level-keyboard-hook-in-c
using System.Diagnostics;
using System.Runtime.InteropServices;
using System.Text;

class EscapeKeyDownTracker
{
    enum OutputType
    {
        UnixMillisString,
        UnixMillisBytes,
    }

    private const int WH_KEYBOARD_LL = 13;
    private const int WM_KEYDOWN = 0x0100;
    private const int WM_KEYUP = 0x0101;
    const Keys Key = Keys.Escape;
    private static LowLevelKeyboardProc _proc = HookCallback;
    private static IntPtr _hookID = IntPtr.Zero;

    static bool _isDown;
    static OutputType _outputType;

    public static void Main()
    {
        _outputType = OutputType.UnixMillisString;
        var arguments = Environment.GetCommandLineArgs();

        if(arguments.Contains("--outputbytes"))
        {
            _outputType = OutputType.UnixMillisBytes;
        }

        Output(0L);
        _hookID = SetHook(_proc);
        Application.Run();
        UnhookWindowsHookEx(_hookID);
    }

    private static IntPtr SetHook(LowLevelKeyboardProc proc)
    {
        using (Process curProcess = Process.GetCurrentProcess())
        using (ProcessModule curModule = curProcess.MainModule)
        {
            return SetWindowsHookEx(WH_KEYBOARD_LL, proc,
                GetModuleHandle(curModule.ModuleName), 0);
        }
    }

    private delegate IntPtr LowLevelKeyboardProc(
        int nCode, IntPtr wParam, IntPtr lParam);

    private static IntPtr HookCallback(int nCode, IntPtr wParam, IntPtr lParam)
    {
        if (nCode >= 0)
        {
            Keys vkCode = (Keys)Marshal.ReadInt32(lParam);

            if(vkCode == Key)
            {
                if (wParam == WM_KEYDOWN)
                {
                    if (!_isDown)
                    {
                        _isDown = true;
                        Output(((DateTimeOffset)DateTime.UtcNow).ToUnixTimeMilliseconds());
                    }
                }
                else
                {
                    _isDown = false;
                    Output(0L);
                }
            }
        }
        return CallNextHookEx(_hookID, nCode, wParam, lParam);
    }

    static void Output(long number)
    {
        switch(_outputType)
        {
            case OutputType.UnixMillisString:
                Console.WriteLine(number.ToString());
                break;
            case OutputType.UnixMillisBytes:
                var bytes = BitConverter.GetBytes(number);
                Console.Write(Encoding.UTF8.GetString(bytes));
                break;
            default:
                throw new Exception(_outputType.ToString());
        }
    }

    [DllImport("user32.dll", CharSet = CharSet.Auto, SetLastError = true)]
    private static extern IntPtr SetWindowsHookEx(int idHook,
        LowLevelKeyboardProc lpfn, IntPtr hMod, uint dwThreadId);

    [DllImport("user32.dll", CharSet = CharSet.Auto, SetLastError = true)]
    [return: MarshalAs(UnmanagedType.Bool)]
    private static extern bool UnhookWindowsHookEx(IntPtr hhk);

    [DllImport("user32.dll", CharSet = CharSet.Auto, SetLastError = true)]
    private static extern IntPtr CallNextHookEx(IntPtr hhk, int nCode,
        IntPtr wParam, IntPtr lParam);

    [DllImport("kernel32.dll", CharSet = CharSet.Auto, SetLastError = true)]
    private static extern IntPtr GetModuleHandle(string lpModuleName);
}
