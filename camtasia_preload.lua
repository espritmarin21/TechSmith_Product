-- Camtasia page: On Preload
Window.SetMask(Application.GetWndHandle(), "AutoPlay\\Images\\maskcaf.png", true, 0);

screen = System.GetDisplayInfo();

x = screen.Width - 739 - 10;
y = screen.Height - 481 - 80;

Window.SetPos(Application.GetWndHandle(), x, y);
