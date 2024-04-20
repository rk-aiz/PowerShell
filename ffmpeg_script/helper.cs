using System;
using System.IO;
using System.Windows;
using System.Windows.Data;
using System.Windows.Input;
using System.Windows.Controls;
using System.Windows.Controls.Primitives;
using System.Windows.Media;
using System.Windows.Media.Animation;
using System.Windows.Media.Effects;
using System.Windows.Shapes;
using System.Windows.Interop;
using System.Threading;
using System.Threading.Tasks;
using System.Linq;
using System.Text;
using System.Diagnostics;
using System.Windows.Threading;
using System.Collections.Generic;
using System.Collections.Concurrent;
using System.ComponentModel;
using System.Runtime.CompilerServices;
using System.Runtime.InteropServices;
using System.Globalization;
using System.Windows.Shell;
using System.Windows.Documents;
using Microsoft.Win32.SafeHandles;
using System.Runtime.ConstrainedExecution;
using System.Security.Permissions;
using HelperClasses;

namespace ProgressWindow
{
    internal class Theme
    {
        internal static Color backgroundColor = new Color { A = 255, R = 50, G = 50, B = 50 };
        internal static Brush backgroundBrush = new SolidColorBrush(backgroundColor);
        internal static Brush foregroundBrush = new SolidColorBrush(Colors.WhiteSmoke);

        internal static Brush windowBackgroundBrush = GetFreezedBrush(15, 15, 15);
        internal static Brush highlightForegroundBrush = GetFreezedBrush(106, 199, 255);
        internal static Brush lowlightForegroundBrush = GetFreezedBrush(200, 200, 200);
        internal static Brush lowlightBackgroundBrush = GetFreezedBrush(45, 45, 45);
        internal static Brush borderBrush = GetFreezedBrush(80, 80, 80);
        internal static Brush mouseOverBackgroundBrush = GetFreezedBrush(255, 255, 255, 35);
        internal static Brush pressedBackgroundBrush = GetFreezedBrush(100, 100, 100);
        internal static Brush progressBarBgBrush = GetFreezedBrush(10, 10, 10);
        internal static Brush progressBarFgBrush = GetFreezedBrush(73, 129, 245);
        internal static Brush progressBarStripeBrush = GetFreezedBrush(86, 149, 247);
        internal static Brush toggleOnBrush = GetFreezedBrush(90, 200, 255);
        internal static Brush warningIconBrush = GetFreezedBrush(238, 157, 40);
        internal static Brush progressBarCompletedBrush = GetFreezedBrush(0, 160, 200);
        internal static Brush switchEllipseBrush = GetFreezedBrush(220, 220, 220);
        internal static Brush switchOnEllipseBrush = GetFreezedBrush(20, 20, 20);
        internal static Brush switchBorderBrush = GetFreezedBrush(150, 150, 150);
        internal static Brush switchBackgroundBrush = GetFreezedBrush(30, 30, 30);
        internal static Brush switchMouseOverBackgroundBrush = GetFreezedBrush(70, 70, 70);
        internal static Brush switchOnBackgroundBrush = GetFreezedBrush(0, 120, 220);
        internal static Brush switchOnMouseOverBackgroundBrush = GetFreezedBrush(20, 160, 255);
        internal static Brush snackbarBackgroundBrush = GetFreezedBrush(80, 80, 80, 220);
        internal static Brush spinnerBackgroundBrush = GetFreezedBrush(116, 39, 116);
        internal static Brush spinnerForegroundBrush = GetFreezedBrush(184, 127, 183);
        internal static Brush completedIconBrush = GetFreezedBrush(98, 255, 223);
        internal static Geometry barGeometry = GetGeometry("M 2 0 L 38 0 A 2 2 0 0 1 38 4 L 2 4 A 2 2 0 0 1 2 0 Z");
        internal static Geometry pinGeometry = GetGeometry(
            "M 10.5 1.4 C 10.3 1.4 10.3 1.4 10.2 1.4 C 10.1 1.5 10 1.6 10 1.7 L 8 6 C 7.9 6.2 7.8 6.4 7.7 6.6 C 7.5 6.7 7.3 6.8 7.1 6.9 L 2.7 8.6 L 9.3 15.2 L 10.5 11.1 C 10.6 10.8 10.7 10.6 10.9 10.4 C 11.1 10.2 11.3 10.1 11.5 10 L 16.2 8 C 16.3 7.9 16.5 7.9 16.5 7.8 C 16.6 7.7 16.6 7.6 16.6 7.5 C 16.6 7.3 16.6 7.2 16.4 7.1 L 10.9 1.5 C 10.8 1.4 10.6 1.4 10.5 1.4 Z M 10.5 0.3 C 10.7 0.3 10.9 0.3 11.2 0.4 C 11.3 0.5 11.5 0.6 11.7 0.7 L 17.2 6.3 C 17.4 6.5 17.5 6.7 17.6 6.8 C 17.6 7 17.7 7.3 17.7 7.5 C 17.7 7.8 17.6 8.2 17.5 8.5 C 17.2 8.7 17 8.9 16.6 9.1 L 12 11 C 11.9 11.1 11.8 11.1 11.8 11.2 C 11.7 11.2 11.7 11.3 11.6 11.3 L 10.1 16.5 C 10.1 16.6 10 16.6 9.9 16.7 C 9.8 16.8 9.7 16.9 9.5 16.9 C 9.4 16.9 9.3 16.8 9.2 16.7 L 5.7 13.1 L 0.8 18 L 0 18 L 0 17.2 L 4.9 12.4 L 1.3 8.8 C 1.2 8.7 1.2 8.6 1.2 8.5 C 1.2 8.3 1.2 8.2 1.3 8.1 C 1.3 8 1.4 7.9 1.4 7.9 L 6.7 5.8 C 6.8 5.8 6.9 5.7 8.9 1.3 C 9.1 1 9.3 0.7 9.5 0.5 C 9.8 0.4 10.2 0.3 10.5 0.3 Z"
        );
        internal static Geometry pinnedGeometry = GetGeometry(
            "M 10.5 0.3 C 10.7 0.3 10.9 0.3 11.2 0.4 C 11.3 0.5 11.5 0.6 11.7 0.7 L 17.2 6.3 C 17.4 6.5 17.5 6.7 17.6 6.8 C 17.6 7 17.7 7.3 17.7 7.5 C 17.7 7.8 17.6 8.2 17.5 8.5 C 17.2 8.7 17 8.9 16.6 9.1 L 12 11 C 11.9 11.1 11.8 11.1 11.8 11.2 C 11.7 11.2 11.7 11.3 11.6 11.3 L 10.1 16.5 C 10.1 16.6 10 16.6 9.9 16.7 C 9.8 16.8 9.7 16.9 9.5 16.9 C 9.4 16.9 9.3 16.8 9.2 16.7 L 1.3 8.8 C 1.2 8.7 1.2 8.6 1.2 8.5 C 1.2 8.3 1.2 8.2 1.3 8.1 C 1.3 8 1.4 7.9 1.4 7.9 L 6.7 5.8 C 6.8 5.8 6.9 5.7 8.9 1.3 C 9.1 1 9.3 0.7 9.5 0.5 C 9.8 0.4 10.2 0.3 10.5 0.3 Z"
        );
        internal static Geometry minimiseGeometry = GetGeometry(
            "M 0.75 11.25 a 0.75 0.75 90 0 0 0 1.5 l 13.5 0 a 0.75 0.75 90 0 0 0 -1.5 z M 0 15"
        );
        internal static Geometry promptGeometry = GetGeometry(
            "M 15.1 1.3 A 3.7 3.6 0 0 1 18.8 4.9 L 18.8 15.1 A 3.7 3.7 0 0 1 15.1 18.8 L 4.9 18.8 A 3.6 3.7 0 0 1 1.3 15.1 L 1.3 4.9 A 3.6 3.6 0 0 1 4.9 1.3 Z M 5 2.5 A 2.5 2.5 0 0 0 2.5 5 L 17.5 5 A 2.5 2.5 0 0 0 15 2.5 Z M 15 17.5 A 2.5 2.5 0 0 0 17.5 15 L 17.5 6.3 L 2.5 6.3 L 2.5 15 A 2.5 2.5 0 0 0 5 17.5 Z M 16 14.2 A 0.6 0.6 0 0 1 14.8 14.6 L 12.6 9.9 A 0.6 0.6 0 0 1 13.8 9.3 Z M 4.9 11.7 C 4.9 11.9 4.9 12.2 5 12.4 C 5 12.7 5 12.9 5.1 13.1 C 5.2 13.3 5.4 13.5 5.5 13.6 C 5.7 13.8 6 13.8 6.3 13.8 C 6.5 13.8 6.6 13.8 6.7 13.8 C 6.8 13.7 6.9 13.7 7 13.6 C 7.1 13.5 7.2 13.4 7.2 13.3 C 7.3 13.3 7.3 13.2 7.4 13.1 C 7.4 13 7.5 13 7.6 12.9 C 7.6 12.9 7.7 12.9 7.9 12.9 C 8 12.9 8.2 12.9 8.3 13 C 8.4 13.1 8.4 13.3 8.4 13.4 C 8.4 13.5 8.4 13.6 8.4 13.7 C 8.2 14.1 7.9 14.4 7.5 14.7 C 7.2 14.9 6.7 15 6.3 15 C 5.7 15 5.3 14.9 4.9 14.6 C 4.5 14.3 4.2 14 4 13.5 C 3.9 13.2 3.8 12.8 3.8 12.5 C 3.8 12.2 3.8 11.9 3.8 11.5 C 3.8 11.3 3.8 11.1 3.8 10.9 C 3.9 10.7 3.9 10.5 4 10.3 C 4.2 9.8 4.4 9.4 4.8 9.2 C 5.2 8.9 5.6 8.8 6.1 8.8 C 6.7 8.8 7.2 8.9 7.6 9.1 C 8 9.4 8.2 9.8 8.4 10.4 C 8.4 10.4 8.4 10.5 8.4 10.5 C 8.4 10.7 8.4 10.8 8.3 11 C 8.2 11.1 8 11.1 7.9 11.1 C 7.7 11.1 7.6 11.1 7.5 11 C 7.4 10.9 7.3 10.8 7.3 10.7 C 7.2 10.6 7.1 10.4 7.1 10.3 C 7 10.2 6.9 10.1 6.8 10 C 6.7 10 6.6 9.9 6.5 9.9 C 6.4 9.9 6.3 9.9 6.2 9.9 L 6.1 9.9 C 5.9 9.9 5.7 10 5.5 10.1 C 5.4 10.2 5.3 10.4 5.2 10.5 C 5.1 10.7 5 10.9 5 11.1 C 4.9 11.3 4.9 11.5 4.9 11.7 Z M 10 10.6 A 0.7 0.7 0 0 0 11.4 10.6 A 0.7 0.7 0 0 0 10 10.6 Z M 10 13.5 A 0.7 0.7 0 0 0 11.4 13.5 A 0.7 0.7 0 0 0 10 13.5 Z"
        );
        internal static Geometry suspendGeometry = GetGeometry(
            "M 2.53 15.19 a 1.52 1.52 90 0 1 -1.52 -1.52 l 0 -11.14 a 1.52 1.52 90 0 1 1.52 -1.52 l 2.02 0 a 1.52 1.52 90 0 1 1.52 1.52 l 0 11.14 a 1.52 1.52 90 0 1 -1.52 1.52 z m 9.12 0 a 1.52 1.52 90 0 1 -1.52 -1.52 l 0 -11.14 a 1.52 1.52 90 0 1 1.52 -1.52 l 2.02 0 a 1.52 1.52 90 0 1 1.52 1.52 l 0 11.14 a 1.52 1.52 90 0 1 -1.52 1.52 z m -7.09 -1.02 a 0.5 0.5 90 0 0 0.5 -0.5 l 0 -11.14 a 0.5 0.5 90 0 0 -0.5 -0.5 l -2.02 0 a 0.5 0.5 90 0 0 -0.5 0.5 l 0 11.14 a 0.5 0.5 90 0 0 0.5 0.5 z m 9.12 0 a 0.5 0.5 90 0 0 0.5 -0.5 l 0 -11.14 a 0.5 0.5 90 0 0 -0.5 -0.5 l -2.02 0 a 0.5 0.5 90 0 0 -0.5 0.5 l 0 11.14 a 0.5 0.5 90 0 0 0.5 0.5 Z"
        );
        internal static Geometry resumeGeometry = GetGeometry(
            "M 3.85 13.55 a 1.39 1.39 90 0 1 -2.03 -1.2 l 0 -10.11 a 1.39 1.39 90 0 1 2.02 -1.2 l 9.07 5.06 a 1.39 1.39 90 0 1 0 2.39 l -9.06 5.06 z"
        );
        internal static Geometry cancelGeometry = GetGeometry(
            "M 0 10 a 8.4375 8.4375 90 0 0 16.875 0 a 8.4375 8.4375 90 0 0 -16.875 0 z m 5.8447 3.5947 l 2.5928 -2.6015 l 2.5928 2.6015 a 0.7084 0.7084 90 0 0 1.0019 -1.0019 l -2.6015 -2.5928 l 2.6015 -2.5928 a 0.7084 0.7084 90 0 0 -1.0019 -1.0019 l -2.5928 2.6015 l -2.5928 -2.6015 a 0.7084 0.7084 90 0 0 -1.0019 1.0019 l 2.6015 2.5928 l -2.6015 2.5928 a 0.7084 0.7084 90 0 0 1.0019 1.0019 z"
        );
        internal static Geometry tabLeftGeometry = GetGeometry(
            "M 10 0 L 0 0 A 2.5 2.5 90 0 1 2.5 2.5 L 2.5 25.1 A 5.1 5.1 90 0 0 7.4 30 L 10 30"
        );
        internal static Geometry tabRightGeometry = GetGeometry(
            "M 0 0 L 0 30 L 2.2 30 C 2.86 30 3.5 29.88 4.12 29.62 C 4.74 29.36 5.28 29 7.003 26.903 L 26.46 1.46 C 26.92 1 27.46 0.64 28.08 0.38 C 28.7 0.12 29.34 0 30 0 L 30 0 Z"
        );
        internal static Geometry gearGeometry = GetGeometry(
            "m 5.87 15.99 c -0.23 0 -0.45 0.04 -0.67 0.12 c -0.23 0.09 -0.45 0.18 -0.66 0.28 c -0.22 0.09 -0.44 0.19 -0.66 0.27 c -0.22 0.08 -0.45 0.13 -0.68 0.13 c -0.19 0 -0.37 -0.04 -0.53 -0.13 c -0.17 -0.08 -0.31 -0.19 -0.44 -0.34 c -0.09 -0.1 -0.19 -0.23 -0.3 -0.39 c -0.12 -0.16 -0.23 -0.34 -0.36 -0.54 c -0.12 -0.19 -0.25 -0.4 -0.37 -0.62 c -0.12 -0.22 -0.23 -0.43 -0.33 -0.63 c -0.09 -0.21 -0.17 -0.4 -0.23 -0.59 c -0.05 -0.18 -0.08 -0.33 -0.08 -0.45 c 0 -0.24 0.06 -0.45 0.17 -0.63 c 0.12 -0.19 0.26 -0.36 0.44 -0.51 c 0.17 -0.16 0.36 -0.3 0.56 -0.44 c 0.21 -0.13 0.4 -0.28 0.57 -0.43 c 0.17 -0.15 0.32 -0.32 0.43 -0.49 c 0.12 -0.17 0.18 -0.37 0.18 -0.6 c 0 -0.22 -0.06 -0.42 -0.18 -0.6 c -0.11 -0.17 -0.26 -0.34 -0.44 -0.49 c -0.17 -0.15 -0.36 -0.3 -0.56 -0.44 c -0.2 -0.15 -0.39 -0.3 -0.57 -0.46 c -0.17 -0.16 -0.32 -0.33 -0.44 -0.51 c -0.11 -0.18 -0.17 -0.39 -0.17 -0.62 c 0 -0.12 0.03 -0.27 0.09 -0.45 c 0.06 -0.19 0.14 -0.38 0.24 -0.59 c 0.1 -0.21 0.21 -0.42 0.34 -0.64 c 0.12 -0.22 0.25 -0.43 0.38 -0.62 c 0.12 -0.2 0.25 -0.38 0.36 -0.55 c 0.12 -0.16 0.22 -0.29 0.31 -0.38 c 0.13 -0.14 0.27 -0.25 0.44 -0.33 c 0.17 -0.08 0.34 -0.12 0.53 -0.12 c 0.23 0 0.45 0.05 0.67 0.13 c 0.21 0.08 0.43 0.18 0.64 0.28 c 0.22 0.1 0.43 0.19 0.65 0.28 c 0.22 0.08 0.44 0.12 0.67 0.12 c 0.29 0 0.54 -0.09 0.76 -0.26 c 0.21 -0.18 0.34 -0.42 0.39 -0.7 c 0.06 -0.32 0.12 -0.64 0.18 -0.96 c 0.06 -0.32 0.11 -0.64 0.17 -0.96 c 0.06 -0.27 0.17 -0.5 0.36 -0.67 c 0.19 -0.18 0.41 -0.29 0.69 -0.34 c 0.26 -0.05 0.52 -0.08 0.79 -0.1 c 0.27 -0.01 0.53 -0.02 0.79 -0.02 c 0.27 0 0.55 0.01 0.82 0.03 c 0.27 0.02 0.54 0.05 0.81 0.11 c 0.27 0.05 0.5 0.16 0.67 0.34 c 0.18 0.17 0.29 0.4 0.35 0.67 c 0.06 0.32 0.11 0.64 0.16 0.95 c 0.05 0.31 0.11 0.63 0.17 0.95 c 0.05 0.28 0.18 0.51 0.4 0.69 c 0.21 0.18 0.46 0.27 0.75 0.27 c 0.23 0 0.45 -0.04 0.67 -0.12 c 0.23 -0.09 0.45 -0.18 0.66 -0.28 c 0.22 -0.09 0.44 -0.19 0.66 -0.27 c 0.22 -0.08 0.45 -0.13 0.68 -0.13 c 0.2 0 0.38 0.04 0.54 0.12 c 0.16 0.09 0.3 0.2 0.43 0.35 c 0.09 0.1 0.19 0.23 0.3 0.39 c 0.12 0.17 0.23 0.34 0.36 0.54 c 0.12 0.19 0.25 0.4 0.37 0.62 c 0.12 0.22 0.23 0.43 0.33 0.63 c 0.09 0.21 0.17 0.4 0.23 0.59 c 0.05 0.18 0.08 0.33 0.08 0.45 c 0 0.25 -0.06 0.46 -0.17 0.64 c -0.12 0.18 -0.26 0.35 -0.44 0.5 c -0.17 0.16 -0.36 0.3 -0.56 0.44 c -0.21 0.13 -0.4 0.28 -0.57 0.43 c -0.17 0.15 -0.32 0.32 -0.43 0.49 c -0.12 0.17 -0.18 0.37 -0.18 0.6 c 0 0.22 0.06 0.42 0.18 0.6 c 0.11 0.17 0.26 0.34 0.44 0.49 c 0.17 0.15 0.36 0.3 0.56 0.44 c 0.2 0.15 0.39 0.3 0.57 0.46 c 0.17 0.16 0.32 0.33 0.44 0.51 c 0.11 0.18 0.17 0.39 0.17 0.63 c 0 0.13 -0.03 0.28 -0.09 0.46 c -0.06 0.18 -0.14 0.37 -0.24 0.58 c -0.1 0.21 -0.21 0.42 -0.34 0.63 c -0.12 0.22 -0.25 0.42 -0.38 0.62 c -0.12 0.2 -0.25 0.37 -0.37 0.54 c -0.12 0.16 -0.22 0.29 -0.31 0.39 c -0.13 0.14 -0.27 0.25 -0.43 0.33 c -0.16 0.08 -0.33 0.12 -0.52 0.12 c -0.22 0 -0.44 -0.05 -0.66 -0.13 c -0.23 -0.08 -0.45 -0.18 -0.67 -0.28 c -0.22 -0.1 -0.44 -0.19 -0.66 -0.28 c -0.23 -0.08 -0.44 -0.12 -0.65 -0.12 c -0.29 0 -0.51 0.05 -0.66 0.17 c -0.16 0.12 -0.28 0.27 -0.36 0.46 c -0.09 0.18 -0.15 0.39 -0.19 0.61 c -0.03 0.23 -0.07 0.44 -0.11 0.65 c -0.03 0.17 -0.06 0.33 -0.09 0.49 c -0.03 0.16 -0.06 0.33 -0.09 0.5 c -0.06 0.28 -0.17 0.5 -0.35 0.68 c -0.19 0.17 -0.42 0.28 -0.7 0.33 c -0.26 0.05 -0.52 0.08 -0.78 0.1 c -0.27 0.01 -0.53 0.02 -0.8 0.02 c -0.27 0 -0.55 -0.01 -0.82 -0.03 c -0.27 -0.02 -0.54 -0.05 -0.81 -0.11 c -0.27 -0.05 -0.5 -0.16 -0.67 -0.34 c -0.18 -0.18 -0.29 -0.41 -0.35 -0.68 c -0.06 -0.31 -0.11 -0.63 -0.16 -0.94 c -0.05 -0.32 -0.11 -0.63 -0.17 -0.95 c -0.05 -0.28 -0.18 -0.51 -0.4 -0.69 c -0.21 -0.18 -0.46 -0.27 -0.75 -0.27 z m 5.53 2.66 c 0.02 -0.14 0.05 -0.32 0.08 -0.53 c 0.04 -0.21 0.07 -0.43 0.11 -0.65 c 0.04 -0.22 0.08 -0.43 0.13 -0.63 c 0.04 -0.21 0.09 -0.37 0.14 -0.49 c 0.18 -0.49 0.47 -0.88 0.87 -1.17 c 0.41 -0.3 0.87 -0.44 1.4 -0.44 c 0.18 0 0.38 0.03 0.61 0.09 c 0.23 0.06 0.47 0.13 0.71 0.22 c 0.25 0.08 0.48 0.17 0.71 0.26 c 0.23 0.09 0.43 0.17 0.61 0.24 c 0.3 -0.37 0.57 -0.75 0.81 -1.16 c 0.23 -0.41 0.44 -0.83 0.61 -1.26 l 0 -0.01 l -1.49 -1.27 c -0.27 -0.23 -0.49 -0.51 -0.64 -0.83 c -0.15 -0.32 -0.22 -0.66 -0.22 -1.02 c 0 -0.36 0.08 -0.7 0.23 -1.03 c 0.15 -0.32 0.37 -0.6 0.64 -0.83 l 1.47 -1.23 l 0 -0.01 c 0 0 -0.01 -0.04 -0.04 -0.11 c -0.02 -0.07 -0.04 -0.1 -0.04 -0.11 c -0.16 -0.4 -0.35 -0.79 -0.57 -1.16 c -0.21 -0.37 -0.46 -0.72 -0.73 -1.06 l -0.01 0 l -1.84 0.67 c -0.26 0.09 -0.53 0.13 -0.8 0.13 c -0.44 0 -0.85 -0.1 -1.22 -0.32 c -0.31 -0.17 -0.57 -0.41 -0.78 -0.7 c -0.2 -0.29 -0.34 -0.62 -0.4 -0.97 l -0.33 -1.9 c -0.47 -0.08 -0.94 -0.12 -1.42 -0.12 c -0.23 0 -0.47 0.01 -0.7 0.02 c -0.24 0.02 -0.47 0.05 -0.7 0.08 c -0.06 0.32 -0.11 0.65 -0.16 0.96 c -0.05 0.32 -0.12 0.64 -0.19 0.96 c -0.06 0.29 -0.16 0.55 -0.3 0.8 c -0.14 0.24 -0.32 0.45 -0.53 0.63 c -0.21 0.17 -0.44 0.31 -0.7 0.41 c -0.26 0.1 -0.54 0.15 -0.84 0.15 c -0.29 0 -0.57 -0.05 -0.83 -0.14 l -0.01 0 l -1.8 -0.67 l -0.01 0 c -0.3 0.37 -0.57 0.76 -0.81 1.16 c -0.24 0.4 -0.44 0.82 -0.61 1.27 l 0 0 l 1.49 1.27 c 0.27 0.23 0.49 0.51 0.64 0.83 c 0.15 0.32 0.22 0.66 0.22 1.02 c 0 0.36 -0.08 0.7 -0.23 1.03 c -0.15 0.32 -0.37 0.6 -0.64 0.83 l -1.47 1.23 l 0 0.01 c 0 0 0.01 0.04 0.04 0.11 c 0.02 0.07 0.04 0.1 0.04 0.11 c 0.16 0.4 0.35 0.79 0.57 1.16 c 0.21 0.37 0.46 0.72 0.73 1.06 l 0.01 0 l 1.84 -0.67 c 0.26 -0.09 0.53 -0.13 0.8 -0.13 c 0.44 0 0.85 0.1 1.22 0.32 c 0.31 0.17 0.57 0.41 0.78 0.7 c 0.2 0.29 0.34 0.62 0.4 0.97 l 0.33 1.9 c 0.47 0.08 0.94 0.12 1.42 0.12 c 0.23 0 0.47 -0.01 0.7 -0.02 c 0.24 -0.02 0.47 -0.05 0.7 -0.08 z m -5.15 -8.65 a 3.75 3.75 0 0 1 7.5 0 a 3.75 3.75 0 0 1 -7.5 0 z m 6.25 0 a 2.5 2.5 0 0 0 -5 0 l 0 0 a 2.5 2.5 0 0 0 5 0 z"
        );
        internal static Geometry progressGeometry = GetGeometry(
            "m 2.25 7.5938 a 1.4063 1.4063 90 0 0 0 2.8125 a 1.4063 1.4063 90 0 0 -0 -2.8125 z m 1.9776 7.4444 a 1.2657 1.2657 90 0 0 -0 -2.5313 a 1.2657 1.2657 90 0 0 0 2.5313 z m 4.7724 1.8369 a 1.125 1.125 90 0 0 -0 -2.25 a 1.125 1.125 90 0 0 0 2.25 z m 4.7724 -2.1182 a 0.9844 0.9844 90 0 0 -0 -1.9688 a 0.9844 0.9844 90 0 0 0 1.9688 z m 1.9776 -4.9131 a 0.8436 0.8436 90 0 0 -0 -1.6875 a 0.8436 0.8436 90 0 0 0 1.6875 z m -1.9776 -4.9131 a 0.7032 0.7032 90 0 0 -0 -1.4063 a 0.7032 0.7032 90 0 0 0 1.4063 z m -4.7724 -2.1181 a 0.5625 0.5625 90 0 0 -0 -1.125 a 0.5625 0.5625 90 0 0 0 1.125 z m -4.7724 2.9619 a 1.5469 1.5469 90 0 0 -0 -3.0938 a 1.5469 1.5469 90 0 0 0 3.0938 z"
        );
        internal static Geometry oemGeometry = GetGeometry(
            "m 16.3828 6.8203 l -2.1884 2.1885 a 1.6875 1.6875 90 0 1 1.5556 1.6787 l 0 4.5 a 1.6875 1.6875 90 0 1 -1.6875 1.6875 l -11.25 0 a 1.6875 1.6875 90 0 1 -1.6875 -1.6875 l 0 -11.25 a 1.6875 1.6875 90 0 1 1.6875 -1.6875 l 4.5 0 a 1.6875 1.6875 90 0 1 1.6787 1.5556 l 2.1885 -2.1884 a 1.6875 1.6875 90 0 1 2.3906 0 l 2.8125 2.8125 a 1.6875 1.6875 90 0 1 0 2.3906 z m -0.7997 -1.5908 l -2.8125 -2.8125 a 0.5625 0.5625 90 0 0 -0.7911 0 l -2.8125 2.8125 a 0.5625 0.5625 90 0 0 0 0.7911 l 2.8125 2.8125 a 0.5625 0.5625 90 0 0 0.7911 0 l 2.8125 -2.8125 a 0.5625 0.5625 90 0 0 0 -0.7911 z m -7.7081 3.7706 l 0 -5.0625 a 0.5625 0.5625 90 0 0 -0.5625 -0.5625 l -4.5 0 a 0.5625 0.5625 90 0 0 -0.5625 0.5625 l 0 5.0625 z m 2.6719 0 l -1.5469 -1.5468 l 0 1.5468 z m -2.6719 6.75 l 0 -5.625 l -5.625 0 l 0 5.0625 a 0.5625 0.5625 90 0 0 0.5625 0.5625 z m 6.75 -5.0625 a 0.5625 0.5625 90 0 0 -0.5625 -0.5625 l -5.0625 0 l 0 5.625 l 5.0625 0 a 0.5625 0.5625 90 0 0 0.5625 -0.5625 z"
        );
        internal static Geometry switchOutlineGeometry = GetGeometry(
            "m 10 0 a 10 10 0 0 0 0 20 l 20 0 a 10 10 0 0 0 0 -20 z"
        );
        internal static Geometry switchEllipseGeometry = GetGeometry(
            "M 0 -6.5 A 6.5 6.5 0 0 0 0 6.5 A 6.5 6.5 0 0 0 0 -6.5 Z"
        );
        internal static Geometry switchEllipseMouseOverGeometry = GetGeometry(
            "M 0 -7 A 7 7 0 0 0 0 7 A 7 7 0 0 0 0 -7 Z"
        );
        internal static Geometry switchOnEllipseMouseOverGeometry = GetGeometry(
            "M 0 -7.5 A 7.5 7.5 0 0 0 0 7.5 A 7.5 7.5 0 0 0 0 -7.5 Z"
        );
        internal static Geometry openfolderGeometry = GetGeometry(
            "M 3.06 18.75 A 3.06 3.06 0 0 1 0 15.69 L 0 4.31 A 3.06 3.06 0 0 1 3.06 1.25 L 6.88 1.25 C 7.32 1.25 7.71 1.32 8.03 1.46 C 8.35 1.6 8.65 1.79 8.91 2.02 C 9.17 2.26 9.41 2.52 9.63 2.82 C 9.85 3.12 10.08 3.43 10.31 3.75 L 15.67 3.75 A 3.06 3.06 0 0 1 18.75 6.77 C 19.06 7.01 19.29 7.3 19.46 7.65 C 19.63 7.99 19.72 8.36 19.72 8.75 C 19.72 8.81 19.72 8.87 19.72 8.92 C 19.72 8.98 19.71 9.03 19.7 9.09 L 18.73 16.05 C 18.68 16.43 18.56 16.78 18.38 17.1 C 18.2 17.43 17.97 17.72 17.7 17.96 C 17.42 18.21 17.11 18.4 16.77 18.54 C 16.42 18.68 16.06 18.75 15.68 18.75 Z M 17.39 6.26 C 17.33 6.07 17.24 5.9 17.12 5.75 C 17 5.59 16.87 5.46 16.71 5.35 C 16.55 5.24 16.38 5.15 16.2 5.09 C 16.02 5.03 15.83 5 15.63 5 L 9.69 5 L 8.38 3.25 C 8.2 3.02 7.98 2.83 7.71 2.7 C 7.45 2.57 7.17 2.5 6.88 2.5 L 3.13 2.5 A 1.88 1.88 0 0 0 1.25 4.38 L 1.25 15.63 C 1.25 15.66 1.25 15.7 1.25 15.74 C 1.26 15.77 1.26 15.81 1.26 15.85 L 2.83 8.24 C 2.89 7.96 3 7.69 3.15 7.45 C 3.3 7.2 3.49 6.99 3.71 6.82 C 3.92 6.64 4.17 6.5 4.44 6.4 C 4.71 6.3 4.99 6.25 5.28 6.25 L 17.23 6.25 C 17.26 6.25 17.29 6.25 17.31 6.25 C 17.33 6.25 17.36 6.25 17.39 6.26 Z M 15.63 17.5 C 15.87 17.5 16.09 17.46 16.3 17.38 C 16.52 17.3 16.7 17.18 16.87 17.04 C 17.04 16.89 17.17 16.72 17.28 16.52 C 17.39 16.33 17.46 16.11 17.49 15.88 L 18.46 8.93 C 18.46 8.89 18.47 8.86 18.47 8.84 C 18.47 8.81 18.47 8.78 18.47 8.75 C 18.47 8.58 18.43 8.42 18.37 8.27 C 18.3 8.11 18.22 7.98 18.11 7.87 C 17.99 7.75 17.86 7.66 17.71 7.6 C 17.57 7.53 17.4 7.5 17.23 7.5 L 5.28 7.5 C 5.13 7.5 4.99 7.52 4.86 7.57 C 4.72 7.62 4.6 7.69 4.49 7.78 C 4.38 7.87 4.29 7.97 4.21 8.1 C 4.13 8.22 4.08 8.35 4.05 8.5 L 2.25 17.28 C 2.53 17.43 2.82 17.5 3.13 17.5 Z"
        );
        internal static Geometry completedGeometry = GetGeometry(
            "M 0 9.375 A 9.375 9.375 0 0 1 18.75 9.375 A 9.375 9.375 0 0 1 0 9.375 Z M 17.175 9.375 A 7.8 7.8 0 0 0 1.575 9.375 A 7.8 7.8 0 0 0 17.175 9.375 Z M 4.3476 9.9024 A 0.5274 0.5274 90 0 1 5.4024 8.8476 L 7.875 11.3086 L 13.3476 5.8476 A 0.5274 0.5274 90 0 1 14.4024 6.9024 L 8.4024 12.9024 C 8.254 13.0508 8.0782 13.125 7.875 13.125 C 7.6718 13.125 7.496 13.0508 7.3476 12.9024 L 4.3476 9.9024 Z"
        );

        internal static Geometry playGeometry = GetGeometry(
            "m 3.5 15.98 l 0 -11.96 a 1.67 1.67 0 0 1 2.57 -1.39 l 9.3 5.96 a 1.67 1.67 0 0 1 0 2.82 l -9.3 5.96 a 1.67 1.67 0 0 1 -2.57 -1.39 z m 1.67 -11.96 l 0 11.96 l 9.29 -5.98 z"
        );
        static Theme()
        {
        }

        private static Geometry GetGeometry(string source)
        {
            var geometry = Geometry.Parse(source);
            return geometry;
        }

        private static SolidColorBrush GetFreezedBrush(byte R, byte G, byte B, byte A = 255)
        {
            var brush = new SolidColorBrush(
                new Color { A = A, R = R, G = G, B = B }
            );
            brush.Freeze();
            return brush;
        }
    }

    public class MainWindow : Window
    {
        private ViewModel _viewModel;
        private Dispatcher _dp = Dispatcher.CurrentDispatcher;
        private TaskbarItemInfo _taskbarItemInfo = new TaskbarItemInfo();
        public double ProgressProxy
        { 
            get { return (double)GetValue(ProgressProxyProperty); } 
            set { SetValue(ProgressProxyProperty, value); } 
        }
        public static readonly DependencyProperty ProgressProxyProperty = 
            DependencyProperty.Register("ProgressProxy", typeof(double),
                typeof(MainWindow), new PropertyMetadata(0.0, ProgressProxyMethod));

        private static void ProgressProxyMethod(DependencyObject d, DependencyPropertyChangedEventArgs e)
        {
            if ((double)e.OldValue != (double)e.NewValue) {
                var source = d as MainWindow;
                source._taskbarItemInfo.ProgressValue = (double)e.NewValue / 100;
            }
        }

        public TaskbarItemProgressState ProgressStateProxy
        { 
            get { return (TaskbarItemProgressState)GetValue(ProgressStateProxyProperty); } 
            set { SetValue(ProgressStateProxyProperty, value); } 
        }
        public static readonly DependencyProperty ProgressStateProxyProperty = 
            DependencyProperty.Register("ProgressStateProxy", typeof(TaskbarItemProgressState),
                typeof(MainWindow), new PropertyMetadata(TaskbarItemProgressState.None, ProgressStateProxyMethod));
        private static void ProgressStateProxyMethod(DependencyObject d, DependencyPropertyChangedEventArgs e)
        {
            if ((TaskbarItemProgressState)e.OldValue != (TaskbarItemProgressState)e.NewValue) {
                var source = d as MainWindow;
                source._taskbarItemInfo.ProgressState = (TaskbarItemProgressState)e.NewValue;
            }
        }

        public MainWindow(ViewModel viewModel)
        {
            _viewModel = viewModel;
            DataContext = viewModel;
            Style = CreateStyle();
            InitializeComponent();

            Width = 600;
            MinHeight = 220;
            SizeToContent = SizeToContent.Height;
            ShowActivated = true;
            
            Background = Theme.windowBackgroundBrush;
            ResizeMode = ResizeMode.CanMinimize;

            SetBinding(Window.TitleProperty, new OneWayBinding("WindowTitle"));
            SetBinding(Window.WindowStateProperty, new Binding("WindowState"){
                Mode = BindingMode.TwoWay
            });
            SetBinding(Window.TopmostProperty, new OneWayBinding("WindowTopmost"));
            Loaded += (sender, e) => { viewModel.WindowTopmost = false; };

            SetBinding(
                ProgressStateProxyProperty,
                new OneWayBinding("ProgressStatus"){
                    Converter = TaskbarItemProgressStateConverter.I,
                    ConverterParameter = ProgressStatus.Completed
                }
            );
            SetBinding(ProgressProxyProperty, new OneWayBinding("Progress"));
            TaskbarItemInfo = _taskbarItemInfo;
        }

        private static Style CreateStyle()
        {
            var presenter = new FrameworkElementFactory(typeof(ContentPresenter), "presenter");
            var decorator = new FrameworkElementFactory(typeof(AdornerDecorator), "decorator");
            decorator.AppendChild(presenter);

            var border = new FrameworkElementFactory(typeof(Border), "border");
            border.SetValue(Border.BackgroundProperty, new TemplateBindingExtension(Control.BackgroundProperty));
            border.AppendChild(decorator);

            var root = new FrameworkElementFactory(typeof(Grid), "TemplateRoot");
            root.AppendChild(border);

            var ct = new ControlTemplate(typeof(Window)){
                VisualTree = root,
            };

            var windowChrome = new WindowChrome{
                CaptionHeight = 0,
                CornerRadius = new CornerRadius(0),
                GlassFrameThickness = new Thickness(0),
                NonClientFrameEdges= NonClientFrameEdges.None,
                ResizeBorderThickness= new Thickness(0),
                UseAeroCaptionButtons= false,
            };
            var style = new Style(typeof(Window));
            style.Setters.Add(new Setter(Control.TemplateProperty, ct));
            style.Setters.Add(new Setter(WindowChrome.WindowChromeProperty, windowChrome));

            return style;
        }

        private void InitializeComponent()
        {
            var header = new CustomHeader();
            header.HeaderDrag += (sender, e) => {
                if (((UIElement)sender).IsMouseDirectlyOver &&
                        e.LeftButton == MouseButtonState.Pressed) {
                    DragMove();
                }
            };
            var footer = new CustomFooter();

            var loadingPanel = new LoadingMessage{ GridRowSpan = 2, VerticalAlignment = VerticalAlignment.Top };
            loadingPanel.SetBinding(Snackbar.RequestVisibleProperty, new OneWayBinding("Busy"));

            var completePanel = new CompleteMessage{ GridRowSpan = 2, VerticalAlignment = VerticalAlignment.Top };
            completePanel.SetBinding(
                Snackbar.RequestVisibleProperty,
                new OneWayBinding("ProgressStatus"){
                    Converter = EnumToBooleanConverter.I,
                    ConverterParameter = ProgressStatus.Completed
                }
            );

            var tabControl = new CustomTabControl{
                Header = header
            };
            var visualRoot = new Grid();

            visualRoot.RowDefinitions.Add(new RowDefinition { Height = new GridLength(1.0, GridUnitType.Star) });
            visualRoot.RowDefinitions.Add(new RowDefinition{ Height = new GridLength(40) });

            Grid.SetRow(tabControl, 0);
            Grid.SetRow(footer, 1);

            Grid.SetRowSpan(tabControl, 2);

            visualRoot.Children.Add(tabControl);
            visualRoot.Children.Add(footer);
            visualRoot.Children.Add(loadingPanel);
            visualRoot.Children.Add(completePanel);

            Content = visualRoot;
        }

        new public async Task Close()
        {
            await _dp.InvokeAsync(() => {
                DialogResult = true;
                //base.Close();
            });
        }

        public void DoEvents(DispatcherPriority priority = DispatcherPriority.Background)
        {
            DispatcherFrame frame = new DispatcherFrame();
            _dp.BeginInvoke(priority, new DispatcherOperationCallback(obj =>
            {
                ((DispatcherFrame)obj).Continue = false;
                return null;
            }), frame);
            Dispatcher.PushFrame(frame);
        }
    }

    public class CustomTabControl : TabControl
    {
        public object Header
        {
            get { return (object)GetValue(CustomTabControl.HeaderProperty ); }
            set { SetValue(CustomTabControl.HeaderProperty , value); }
        }

        public static readonly DependencyProperty HeaderProperty =
            DependencyProperty.Register("Header", typeof(object), typeof(CustomTabControl),
                                            new PropertyMetadata(null));

        public CustomTabControl()
        {
            Background = Theme.backgroundBrush;
            Style = CreateStyle();
            InitializeComponent();
        }

        private static Style CreateStyle()
        {
            var content = new FrameworkElementFactory(typeof(ContentPresenter), "PART_SelectedContentHost");
            content.SetValue(ContentPresenter.ContentSourceProperty, "SelectedContent");
            //content.SetValue(FrameworkElement.MarginProperty, new Thickness(4));

            var row0 = new FrameworkElementFactory(typeof(RowDefinition));
            row0.SetValue(RowDefinition.HeightProperty, GridLength.Auto);

            var row1 = new FrameworkElementFactory(typeof(RowDefinition));
            row1.SetValue(RowDefinition.HeightProperty, new GridLength(1.0, GridUnitType.Star));

            var row2 = new FrameworkElementFactory(typeof(RowDefinition));
            row2.SetValue(RowDefinition.HeightProperty, GridLength.Auto);

            var header = new FrameworkElementFactory(typeof(ContentControl));
            header.SetValue(ContentControl.ContentProperty, new TemplateBindingExtension(CustomTabControl.HeaderProperty));
            header.SetValue(Grid.RowProperty, 0);

            var border = new FrameworkElementFactory(typeof(Border), "Border");
            border.SetValue(Control.BackgroundProperty, new TemplateBindingExtension(Control.BackgroundProperty));
            border.SetValue(Border.CornerRadiusProperty, new CornerRadius(0, 0, 3, 3));
            border.SetValue(Grid.RowProperty, 1);
            border.AppendChild(content);

            var tabPanel = new FrameworkElementFactory(typeof(TabPanel), "HeaderPanel");
            tabPanel.SetValue(Panel.ZIndexProperty, 1);
            tabPanel.SetValue(FrameworkElement.MarginProperty, new Thickness(5, 0, 5, 10));
            tabPanel.SetValue(Panel.IsItemsHostProperty, true);
            tabPanel.SetValue(Panel.BackgroundProperty, Brushes.Transparent);
            tabPanel.SetValue(Grid.RowProperty, 2);
            
            var root = new FrameworkElementFactory(typeof(Grid), "TemplateRoot");
            root.AppendChild(row0);
            root.AppendChild(row1);
            root.AppendChild(row2);
            root.AppendChild(header);
            root.AppendChild(tabPanel);
            root.AppendChild(border);

            var ct = new ControlTemplate(typeof(TabControl)){
                VisualTree = root,
            };

            var style = new Style(typeof(TabControl));
            style.Setters.Add(new Setter(Control.TemplateProperty, ct));
            style.Setters.Add(new Setter(FrameworkElement.OverridesDefaultStyleProperty, true));
            style.Setters.Add(new Setter(UIElement.SnapsToDevicePixelsProperty, true));
            return style;
        }

        private void InitializeComponent()
        {
            var statusDescription = new CustomTextBlock("StatusDescription"){
                FontFamily = new FontFamily("Consolas"),
                GridRow = 3
            };

            var operationText = new CustomTextBlock("CurrentOperation"){
                FontFamily = new FontFamily("Yu Gothic UI Semibold"),
                Foreground = Theme.highlightForegroundBrush,
                GridRow = 0
            };

            var progressBar = new CustomProgressBar{ GridRow = 1 };
            progressBar.SetBinding(CustomProgressBar.SmoothValueProperty, new OneWayBinding("Progress"));
            progressBar.SetBinding(CustomProgressBar.LabelTextProperty, new OneWayBinding("ProgressLabel"));
            progressBar.SetBinding(
                CustomProgressBar.IsActiveProperty,
                new OneWayBinding("ProgressStatus"){
                    Converter = EnumToBooleanConverter.I,
                    ConverterParameter = ProgressStatus.Processing
            });

            var remainingText = new CustomTextBlock(
                "ProgressRemaining",
                "Estimated remaining time : {0:hh}:{0:mm}:{0:ss}"
            ){
                FontFamily = new FontFamily("Verdana"),
                GridRow = 2
            };

            var progressGrid = new Grid();

            progressGrid.RowDefinitions.Add(new RowDefinition{ Height = new GridLength(30) });
            progressGrid.RowDefinitions.Add(new RowDefinition{ Height = GridLength.Auto });
            progressGrid.RowDefinitions.Add(new RowDefinition{ Height = new GridLength(25) });
            progressGrid.RowDefinitions.Add(new RowDefinition { Height = new GridLength(1.0, GridUnitType.Star) });

            progressGrid.Children.Add(operationText);
            progressGrid.Children.Add(progressBar);
            progressGrid.Children.Add(remainingText);
            progressGrid.Children.Add(statusDescription);

            var progressTab = new CustomTabItem{
                Header = "Progress",
                Icon = new System.Windows.Shapes.Path{
                    Data = Theme.progressGeometry,
                    Fill = Theme.highlightForegroundBrush,
                    Stroke = Theme.highlightForegroundBrush,
                    Margin = new Thickness(6, 0, 4, 0)
                },
                Content = progressGrid,
            };

            var optionsGrid = new Grid();

            optionsGrid.RowDefinitions.Add(new RowDefinition{ Height = GridLength.Auto });
            optionsGrid.RowDefinitions.Add(new RowDefinition{ Height = GridLength.Auto });
            optionsGrid.RowDefinitions.Add(new RowDefinition{ Height = GridLength.Auto });

            var switchAutoClose = new CustomSwitch{
                Content = new CustomTextBlock("AutoCloseText") { FontSize = 14.0},
                Margin = new Thickness(20, 15, 40, 7.5),
                GridRow = 0
            };
            switchAutoClose.SetBinding(CustomSwitch.IsOnProperty, new TwoWayBinding("AutoClose"));

            var switchAutoPlay = new CustomSwitch{
                Content = new CustomTextBlock("AutoPlayText") { FontSize = 14.0},
                Margin = new Thickness(20, 7.5, 40, 7.5),
                GridRow = 1
            };
            switchAutoPlay.SetBinding(CustomSwitch.IsOnProperty, new TwoWayBinding("AutoPlay"));

            var switchOpenExplorer = new CustomSwitch{
                Content = new CustomTextBlock("OpenExplorerText") { FontSize = 14.0},
                Margin = new Thickness(20, 7.5, 40, 7.5),
                GridRow = 2
            };
            switchOpenExplorer.SetBinding(CustomSwitch.IsOnProperty, new TwoWayBinding("OpenExplorer"));

            optionsGrid.Children.Add(switchAutoClose);
            optionsGrid.Children.Add(switchAutoPlay);
            optionsGrid.Children.Add(switchOpenExplorer);

            var optionsTab = new CustomTabItem{
                Header = "Options",
                Icon = new System.Windows.Shapes.Path{
                    Data = Theme.oemGeometry,
                    Fill = Theme.highlightForegroundBrush,
                    Margin = new Thickness(10, 0, 4, 0)
                },
                Content = optionsGrid
            };

            Items.Add(progressTab);
            Items.Add(optionsTab);
        }
    }

    public class CustomTabItem : TabItem
    {

        public object Icon
        {
            get { return (object)GetValue(CustomTabItem.IconProperty); }
            set { SetValue(CustomTabItem.IconProperty, value); }
        }

        public static readonly DependencyProperty IconProperty =
            DependencyProperty.Register("Icon", typeof(object), typeof(CustomTabItem),
                                            new PropertyMetadata(null));

        public CustomTabItem()
        {
            Height = 30;
            Style = CreateStyle();
        }

        private static Style CreateStyle()
        {
            var leadingIcon = new FrameworkElementFactory(typeof(ContentControl), "Icon");
            leadingIcon.SetValue(ContentControl.ContentProperty, new TemplateBindingExtension(CustomTabItem.IconProperty));
            leadingIcon.SetValue(FrameworkElement.HorizontalAlignmentProperty, HorizontalAlignment.Center);
            leadingIcon.SetValue(FrameworkElement.VerticalAlignmentProperty, VerticalAlignment.Center);
            leadingIcon.SetValue(Grid.ColumnProperty, 1);

            var leadingIconBorder = new FrameworkElementFactory(typeof(Border), "IconBorder");
            leadingIconBorder.SetValue(Control.BackgroundProperty, new TemplateBindingExtension(Control.BackgroundProperty));
            leadingIconBorder.SetValue(Grid.ColumnProperty, 1);
            leadingIconBorder.AppendChild(leadingIcon);

            var content = new FrameworkElementFactory(typeof(ContentPresenter), "ContentSite");
            content.SetValue(ContentPresenter.ContentSourceProperty, "Header");
            content.SetValue(FrameworkElement.MarginProperty, new Thickness(0, 0, 10, 0));
            content.SetValue(ContentPresenter.HorizontalAlignmentProperty, HorizontalAlignment.Center);
            content.SetValue(ContentPresenter.VerticalAlignmentProperty, VerticalAlignment.Center);
            content.SetValue(Control.FontFamilyProperty, new FontFamily("Yu Gothic UI Semibold"));
            content.SetValue(Control.FontSizeProperty, 13.5);

            var column0 = new FrameworkElementFactory(typeof(ColumnDefinition));
            column0.SetValue(ColumnDefinition.WidthProperty, new GridLength(10));

            var column1 = new FrameworkElementFactory(typeof(ColumnDefinition));
            column1.SetValue(ColumnDefinition.WidthProperty, GridLength.Auto);

            var column2 = new FrameworkElementFactory(typeof(ColumnDefinition));
            column2.SetValue(ColumnDefinition.WidthProperty, GridLength.Auto);

            var column3 = new FrameworkElementFactory(typeof(ColumnDefinition));
            column3.SetValue(ColumnDefinition.WidthProperty, new GridLength(30));

            var tabLeft = new FrameworkElementFactory(typeof(System.Windows.Shapes.Path), "TabLeft");
            tabLeft.SetValue(FrameworkElement.HeightProperty, new TemplateBindingExtension(FrameworkElement.HeightProperty));
            tabLeft.SetValue(Shape.FillProperty, new TemplateBindingExtension(Control.BackgroundProperty));
            tabLeft.SetValue(System.Windows.Shapes.Path.DataProperty, Theme.tabLeftGeometry);
            tabLeft.SetValue(Grid.ColumnProperty, 0);

            var tabRight = new FrameworkElementFactory(typeof(System.Windows.Shapes.Path), "TabRight");
            tabRight.SetValue(FrameworkElement.HeightProperty, new TemplateBindingExtension(FrameworkElement.HeightProperty));
            tabRight.SetValue(Shape.FillProperty, new TemplateBindingExtension(Control.BackgroundProperty));
            tabRight.SetValue(System.Windows.Shapes.Path.DataProperty, Theme.tabRightGeometry);
            tabRight.SetValue(Grid.ColumnProperty, 3);

            var border = new FrameworkElementFactory(typeof(Border), "Border");
            border.SetValue(Control.BackgroundProperty, new TemplateBindingExtension(Control.BackgroundProperty));
            border.SetValue(Grid.ColumnProperty, 2);
            border.AppendChild(content);

            var root = new FrameworkElementFactory(typeof(Grid), "TemplateRoot");
            root.SetValue(FrameworkElement.CursorProperty, Cursors.Hand);
            root.SetValue(FrameworkElement.MarginProperty, new Thickness{ Right = -25 });
            root.AppendChild(column0);
            root.AppendChild(column1);
            root.AppendChild(column2);
            root.AppendChild(column3);
            root.AppendChild(tabLeft);
            root.AppendChild(tabRight);
            root.AppendChild(leadingIconBorder);
            root.AppendChild(border);

            var isSelectedTrigger = new Trigger{
                Property = TabItem.IsSelectedProperty,
                Value = true,
            };
            isSelectedTrigger.Setters.Add(new Setter(Panel.ZIndexProperty, 100));
            isSelectedTrigger.Setters.Add(new Setter(Control.ForegroundProperty, Theme.foregroundBrush));
            isSelectedTrigger.Setters.Add(new Setter(Control.BackgroundProperty, Theme.backgroundBrush));

            var mouseOverTrigger = new MultiTrigger();
            mouseOverTrigger.Conditions.Add(new Condition(UIElement.IsMouseOverProperty, true));
            mouseOverTrigger.Conditions.Add(new Condition(TabItem.IsSelectedProperty, false));
            mouseOverTrigger.Setters.Add(new Setter(Control.BackgroundProperty, Theme.lowlightBackgroundBrush));

            var ct = new ControlTemplate(typeof(TabItem)){
                VisualTree = root,
            };
            ct.Triggers.Add(isSelectedTrigger);
            ct.Triggers.Add(mouseOverTrigger);

            var style = new Style(typeof(TabItem));
            style.Setters.Add(new Setter(Control.TemplateProperty, ct));
            style.Setters.Add(new Setter(Control.BackgroundProperty, Brushes.Transparent));
            style.Setters.Add(new Setter(Control.ForegroundProperty, Theme.lowlightForegroundBrush));
            style.Setters.Add(new Setter(Control.ForegroundProperty, Theme.lowlightForegroundBrush));
            return style;
        }
    }

    public class CustomFooter : UserControl
    {
        public CustomFooter()
        {
            InitializeComponent();
        }

        private void InitializeComponent()
        {
            var grid = new Grid{
                VerticalAlignment = VerticalAlignment.Center,
                Margin = new Thickness { Right = 10 }
            };

            grid.ColumnDefinitions.Add(new ColumnDefinition{ Width = new GridLength(1.0, GridUnitType.Star) });
            grid.ColumnDefinitions.Add(new ColumnDefinition{ Width = GridLength.Auto });
            grid.ColumnDefinitions.Add(new ColumnDefinition{ Width = GridLength.Auto });
            grid.ColumnDefinitions.Add(new ColumnDefinition{ Width = GridLength.Auto });

            var promptButtonUnchecked = new DockPanel{
                Width = 125,
                VerticalAlignment = VerticalAlignment.Bottom
            };
            promptButtonUnchecked.Children.Add(new System.Windows.Shapes.Path{
                Data = Theme.promptGeometry,
                Fill = Theme.foregroundBrush,
                Margin = new Thickness{ Left = 5, Right = 5 },
                VerticalAlignment = VerticalAlignment.Center
            });
            promptButtonUnchecked.Children.Add(new TextBlock{
                Text = "Show Console",
                FontFamily = SystemFonts.CaptionFontFamily,
                FontSize = 14,
            });

            var promptButtonChecked = new DockPanel{
                Width = 125,
                VerticalAlignment = VerticalAlignment.Bottom
            };
            
            promptButtonChecked.Children.Add(new System.Windows.Shapes.Path{
                Data = Theme.promptGeometry,
                Fill = Theme.toggleOnBrush,
                Margin = new Thickness{ Left = 5, Right = 5 },
                VerticalAlignment = VerticalAlignment.Center
            });
            promptButtonChecked.Children.Add(new TextBlock{
                Text = "Hide Console",
                FontFamily = SystemFonts.CaptionFontFamily,
                FontSize = 14,
            });

            var promptButton = new CustomToggleButton(promptButtonUnchecked, promptButtonChecked){
                Width = 125,
                Height = 30,
                Margin = new Thickness { Right = 5 },
                GridColumn = 1
            };

            promptButton.SetBinding(ButtonBase.CommandProperty, new OneWayBinding("ShowPromptCommand"));
            promptButton.SetBinding(ButtonBase.CommandParameterProperty, new Binding{
                Path = new PropertyPath(CustomToggleButton.IsCheckedProperty),
                RelativeSource = RelativeSource.Self
            });

            var suspendButton = new DockPanel{
                Width = 90,
                VerticalAlignment = VerticalAlignment.Bottom
            };

            suspendButton.Children.Add(new System.Windows.Shapes.Path{
                Data = Theme.suspendGeometry,
                Fill = Theme.foregroundBrush,
                Margin = new Thickness{ Left = 10, Right = 10 },
                VerticalAlignment = VerticalAlignment.Center
            });
            suspendButton.Children.Add(new TextBlock{
                Text = "Pause",
                FontFamily = SystemFonts.CaptionFontFamily,
                FontSize = 14,
            });

            var resumeButton = new DockPanel{
                Width = 90,
                VerticalAlignment = VerticalAlignment.Bottom
            };

            resumeButton.Children.Add(new System.Windows.Shapes.Path{
                Data = Theme.resumeGeometry,
                Fill = Theme.toggleOnBrush,
                Margin = new Thickness{ Left = 10, Right = 10 },
                VerticalAlignment = VerticalAlignment.Center
            });
            resumeButton.Children.Add(new TextBlock{
                Text = "Resume",
                FontFamily = SystemFonts.CaptionFontFamily,
                FontSize = 14,
            });

            var processControlButton = new CustomToggleButton(suspendButton, resumeButton){
                Width = 90,
                Height = 30,
                Margin = new Thickness { Right = 5 },
                GridColumn = 2
            };
            processControlButton.SetBinding(
                UIElement.VisibilityProperty,
                new OneWayBinding("ProgressStatus"){
                    Converter = EnumToVisibilityConverter.I,
                    ConverterParameter = 1 | 2 | 4
            });
            processControlButton.SetBinding(ButtonBase.CommandProperty, new OneWayBinding("ProcessControlCommand"));
            processControlButton.SetBinding(ButtonBase.CommandParameterProperty, new Binding{
                Path = new PropertyPath(CustomToggleButton.IsCheckedProperty),
                RelativeSource = RelativeSource.Self
            });

            var openFolder = new DockPanel{
                Width = 120,
                VerticalAlignment = VerticalAlignment.Center
            };

            openFolder.Children.Add(new System.Windows.Shapes.Path{
                Data = Theme.openfolderGeometry,
                Fill = Theme.foregroundBrush,
                Margin = new Thickness{ Left = 5, Right = 5 },
                VerticalAlignment = VerticalAlignment.Center
            });
            openFolder.Children.Add(new TextBlock{
                Text = "Open Folder",
                FontFamily = SystemFonts.CaptionFontFamily,
                FontSize = 14,
            });
            var openFolderButton = new TileButton(openFolder){
                Width = 120,
                Height = 30,
                Margin = new Thickness { Right = 5 },
                GridColumn = 2
            };
            openFolderButton.SetBinding(ButtonBase.CommandProperty, new OneWayBinding("OpenFolderCommand"));

            openFolderButton.SetBinding(
                UIElement.VisibilityProperty,
                new OneWayBinding("ProgressStatus"){
                    Converter = EnumToVisibilityConverter.I,
                    ConverterParameter = ProgressStatus.Completed
            });

            var cancelButton = new DockPanel{
                Width = 90,
                VerticalAlignment = VerticalAlignment.Center
            };

            cancelButton.Children.Add(new System.Windows.Shapes.Path{
                Data = Theme.cancelGeometry,
                Fill = Theme.warningIconBrush,
                Margin = new Thickness{ Left = 10, Right = 10 },
                VerticalAlignment = VerticalAlignment.Center
            });
            cancelButton.Children.Add(new TextBlock{
                Text = "Quit",
                FontFamily = SystemFonts.CaptionFontFamily,
                FontSize = 14,
            });

            var processCancelButton = new TileButton(cancelButton){
                Width = 90,
                Height = 30,
                Margin = new Thickness { Right = 5 },
                GridColumn = 3
            };
            processCancelButton.SetBinding(ButtonBase.CommandProperty, new OneWayBinding("ProcessExitCommand"));

            grid.Children.Add(promptButton);
            grid.Children.Add(processControlButton);
            grid.Children.Add(openFolderButton);
            grid.Children.Add(processCancelButton);

            Content = grid;
        }
    }

    public class CustomHeader : UserControl
    {
        public event MouseEventHandler HeaderDrag = (sender, e) => {};

        public CustomHeader()
        {
            InitializeComponent();
        }

        private void InitializeComponent()
        {
            var grid = new Grid { VerticalAlignment = VerticalAlignment.Stretch };

            grid.ColumnDefinitions.Add(new ColumnDefinition{ Width = GridLength.Auto });
            grid.ColumnDefinitions.Add(new ColumnDefinition{ Width = new GridLength(1.0, GridUnitType.Star) });
            grid.ColumnDefinitions.Add(new ColumnDefinition{ Width = GridLength.Auto });
            grid.ColumnDefinitions.Add(new ColumnDefinition{ Width = GridLength.Auto });

            var icon = new TextBlock{
                Text = "FFMPEG",
                Foreground = Theme.foregroundBrush,
                FontFamily = new FontFamily("Impact"),
                FontSize = 16.0,
                Margin = new Thickness{ Left = 10, Right = 10 },
                TextAlignment = TextAlignment.Left,
                TextWrapping = TextWrapping.NoWrap,
                VerticalAlignment = VerticalAlignment.Center
            };

            var barIcon = new System.Windows.Shapes.Path{
                Data = Theme.barGeometry,
                Fill = Theme.lowlightForegroundBrush,
                Stroke = Theme.lowlightForegroundBrush,
                HorizontalAlignment = HorizontalAlignment.Center,
                VerticalAlignment = VerticalAlignment.Center,
            };

            var minimiseButton = new TileButton(
                new System.Windows.Shapes.Path{
                    Data = Theme.minimiseGeometry,
                    Fill = Theme.foregroundBrush
                }
            ){
                GridColumn = 2,
                Margin = new Thickness{ Top = 5, Right = 5 }
            };
            minimiseButton.SetBinding(ButtonBase.CommandProperty, new OneWayBinding("MinimiseCommand"));

            var pinButton = new CustomToggleButton(
                new System.Windows.Shapes.Path{
                    Data = Theme.pinGeometry,
                    Fill = Theme.foregroundBrush,
                },
                new System.Windows.Shapes.Path{
                    Data = Theme.pinnedGeometry,
                    Fill = Theme.toggleOnBrush
                }
            ){
                GridColumn = 3,
                Margin = new Thickness{ Top = 5, Right = 5 }
            };
            pinButton.SetBinding(ButtonBase.CommandProperty, new OneWayBinding("TopmostCommand"));
            pinButton.SetBinding(ButtonBase.CommandParameterProperty, new Binding{
                Path = new PropertyPath(CustomToggleButton.IsCheckedProperty),
                RelativeSource = RelativeSource.Self
            });

            var draggable = new Border {
                Background = Brushes.Transparent,
                HorizontalAlignment = HorizontalAlignment.Stretch,
                VerticalAlignment = VerticalAlignment.Stretch
            };
            draggable.MouseMove += (sender, e) => { HeaderDrag.Invoke(sender, e); };

            Grid.SetColumnSpan(barIcon, 4);
            Grid.SetColumnSpan(draggable, 4);

            grid.Children.Add(icon);
            grid.Children.Add(barIcon);
            grid.Children.Add(draggable);
            grid.Children.Add(minimiseButton);
            grid.Children.Add(pinButton);

            var border = new Border{
                Background = Theme.backgroundBrush,
                BorderThickness = new Thickness(0),
                Child = grid
            };

            Content = border;
        }
    }

    class TileButton : ButtonBase
    {
        public int GridRow
        {
            set { Grid.SetRow(this, value); }
        }

        public int GridColumn
        {
            set { Grid.SetColumn(this, value); }
        }

        public TileButton(object content) : this()
        {
            Template = CreateTemplate();
            Content = content;
        }

        protected TileButton()
        {
            VerticalAlignment = VerticalAlignment.Center;
            VerticalContentAlignment = VerticalAlignment.Center;
            HorizontalContentAlignment = HorizontalAlignment.Center;
            Foreground = Theme.foregroundBrush;
            Background = Brushes.Transparent;
            FontFamily = new FontFamily("Segoe MDL2 Assets");
            FontSize = 17.0;
            Cursor = Cursors.Hand;
            Margin = new Thickness{ Left = 0, Right = 5 };
            Height = 30.0;
            Width = 30.0;
        }

        protected static ControlTemplate CreateTemplate()
        {
            var content = new FrameworkElementFactory(typeof(ContentPresenter), "presenter");
            content.SetValue(ContentPresenter.VerticalAlignmentProperty, VerticalAlignment.Center);
            content.SetValue(ContentPresenter.HorizontalAlignmentProperty, HorizontalAlignment.Center);

            var border = new FrameworkElementFactory(typeof(Border), "border");
            border.SetValue(Control.BackgroundProperty, new TemplateBindingExtension(Control.BackgroundProperty));
            border.SetValue(Border.CornerRadiusProperty, new CornerRadius(5));
            border.AppendChild(content);

            var ct = new ControlTemplate(typeof(ButtonBase)){
                VisualTree = border,
            };

            var mouseOverTrigger = new Trigger{
                Property = UIElement.IsMouseOverProperty,
                Value = true,
            };
            mouseOverTrigger.Setters.Add(new Setter(Border.BackgroundProperty, Theme.mouseOverBackgroundBrush, "border"));
            ct.Triggers.Add(mouseOverTrigger);

            var pressedTrigger = new Trigger{
                Property = ButtonBase.IsPressedProperty,
                Value = true,
            };
            pressedTrigger.Setters.Add(new Setter(Border.BackgroundProperty, Theme.pressedBackgroundBrush, "border"));
            ct.Triggers.Add(pressedTrigger);

            return ct;
        }
    }

    class CustomToggleButton : TileButton
    {
        public bool? IsChecked
        {
            get { return (bool?)GetValue(CustomToggleButton.IsCheckedProperty); }
            set { SetValue(CustomToggleButton.IsCheckedProperty, value); }
        }

        public static readonly DependencyProperty IsCheckedProperty =
            DependencyProperty.Register("IsChecked", typeof(bool?), typeof(CustomToggleButton),
                                        new PropertyMetadata(false));

        public event EventHandler IsCheckedChanged = (sender, e) => {};

        private object _checkedContent;

        public CustomToggleButton(object content, object checkedContent)
        {
            Content = content;
            _checkedContent = checkedContent;
            Style = CreateStyle();
            Click += (sender, e) => {
                switch (IsChecked) {
                    case true:
                        IsChecked = false;
                        break;
                    case null:
                    case false:
                        IsChecked = true;
                        break;
                }

                IsCheckedChanged.Invoke(this, EventArgs.Empty);
            };
        }

        private Style CreateStyle()
        {
            var baseTemplate = CreateTemplate();

            var trigger = new Trigger{
                Property = CustomToggleButton.IsCheckedProperty,
                Value = true,
            };
            trigger.Setters.Add(new Setter(ContentPresenter.ContentProperty, _checkedContent, "presenter"));
            baseTemplate.Triggers.Add(trigger);

            var style = new Style(typeof(CustomToggleButton));
            style.Setters.Add(new Setter(Control.TemplateProperty, baseTemplate));

            return style;
        }
    }

    public class CustomSwitch : ButtonBase
    {
        public bool IsOn
        {
            get { return (bool)GetValue(CustomSwitch.IsOnProperty); }
            set { SetValue(CustomSwitch.IsOnProperty, value); }
        }

        public static readonly DependencyProperty IsOnProperty =
            DependencyProperty.Register("IsOn", typeof(bool), typeof(CustomSwitch),
                                        new PropertyMetadata(false));

        public int GridRow
        {
            set { Grid.SetRow(this, value); }
        }

        public int GridColumn
        {
            set { Grid.SetColumn(this, value); }
        }

        private const double SWITCH_ON_X = 30;
        private const double SWITCH_OFF_X = 11;

        
        private static DoubleAnimation _switchOnAnimation = new DoubleAnimation{
            To = SWITCH_ON_X,
            Duration = new Duration(TimeSpan.FromMilliseconds(150.0))
        };

        private static DoubleAnimation _switchOffAnimation = new DoubleAnimation{
            To = SWITCH_OFF_X,
            Duration = new Duration(TimeSpan.FromMilliseconds(150.0))
        };

        private static PropertyPath _animationTargetProperty = new PropertyPath(
            "(0).(1)",
            UIElement.RenderTransformProperty,
            TranslateTransform.XProperty
        );

        public bool RenderWithOn
        {
            get { return (bool)GetValue(RenderWithOnProperty); }
            set { SetValue(RenderWithOnProperty, value); }
        }
        public static readonly DependencyProperty RenderWithOnProperty =
            DependencyProperty.Register("RenderWithOn", typeof(bool), typeof(CustomSwitch),
                                        new PropertyMetadata(false));

        public CustomSwitch()
        {
            Cursor = Cursors.Hand;
            Style = CreateStyle();
        }

        protected override void OnRender (DrawingContext drawingContext)
        {
            RenderWithOn = IsOn;
            base.OnRender(drawingContext);
        }

        private static Style CreateStyle()
        {
            var ellipse = new FrameworkElementFactory(typeof(System.Windows.Shapes.Path), "ellipse");
            ellipse.SetValue(Shape.FillProperty, Theme.switchEllipseBrush);
            ellipse.SetValue(System.Windows.Shapes.Path.DataProperty, Theme.switchEllipseGeometry);
            ellipse.SetValue(UIElement.RenderTransformProperty, new TranslateTransform(11, 10));
            ellipse.SetValue(Grid.ColumnProperty, 1);
            
            var outline = new FrameworkElementFactory(typeof(System.Windows.Shapes.Path), "outline");
            outline.SetValue(Shape.FillProperty, Theme.switchBackgroundBrush);
            outline.SetValue(Shape.StrokeThicknessProperty, 1.5);
            outline.SetValue(Shape.StrokeProperty, Theme.switchBorderBrush);
            outline.SetValue(System.Windows.Shapes.Path.DataProperty, Theme.switchOutlineGeometry);
            outline.SetValue(Grid.ColumnProperty, 1);

            var content = new FrameworkElementFactory(typeof(ContentPresenter), "content");
            content.SetValue(Grid.ColumnProperty, 0);

            var column0 = new FrameworkElementFactory(typeof(ColumnDefinition));
            column0.SetValue(ColumnDefinition.WidthProperty, new GridLength(1.0, GridUnitType.Star));

            var column1 = new FrameworkElementFactory(typeof(ColumnDefinition));
            column1.SetValue(ColumnDefinition.WidthProperty, GridLength.Auto);

            var root = new FrameworkElementFactory(typeof(Grid), "TemplateRoot");
            root.AppendChild(column0);
            root.AppendChild(column1);
            root.AppendChild(content);
            root.AppendChild(outline);
            root.AppendChild(ellipse);

            var renderWithOnTrigger = new Trigger{
                Property = CustomSwitch.RenderWithOnProperty,
                Value = true,
            };
            renderWithOnTrigger.Setters.Add(new Setter(UIElement.RenderTransformProperty, new TranslateTransform(30, 10), "ellipse"));

            var isOnTrigger = new Trigger{
                Property = CustomSwitch.IsOnProperty,
                Value = true,
            };
            isOnTrigger.Setters.Add(new Setter(Shape.FillProperty, Theme.switchOnEllipseBrush, "ellipse"));
            isOnTrigger.Setters.Add(new Setter(Shape.FillProperty, Theme.switchOnBackgroundBrush, "outline"));
            isOnTrigger.Setters.Add(new Setter(Shape.StrokeProperty, Theme.switchOnBackgroundBrush, "outline"));
            isOnTrigger.EnterActions.Add(
                _switchOnAnimation.Clone().ToStoryboard("ellipse", _animationTargetProperty).ToBegin()
            );
            isOnTrigger.ExitActions.Add(
                _switchOffAnimation.Clone().ToStoryboard("ellipse", _animationTargetProperty).ToBegin()
            );

            var mouseOverTrigger = new Trigger{
                Property = UIElement.IsMouseOverProperty,
                Value = true,
            };
            mouseOverTrigger.Setters.Add(new Setter(Shape.FillProperty, Theme.switchMouseOverBackgroundBrush, "outline"));
            mouseOverTrigger.Setters.Add(new Setter(System.Windows.Shapes.Path.DataProperty, Theme.switchEllipseMouseOverGeometry, "ellipse"));

            var isOnMouseOverTrigger = new MultiTrigger();
            isOnMouseOverTrigger.Conditions.Add(new Condition(UIElement.IsMouseOverProperty, true));
            isOnMouseOverTrigger.Conditions.Add(new Condition(CustomSwitch.IsOnProperty, true));
            isOnMouseOverTrigger.Setters.Add(new Setter(System.Windows.Shapes.Path.DataProperty, Theme.switchOnEllipseMouseOverGeometry, "ellipse"));
            isOnMouseOverTrigger.Setters.Add(new Setter(Shape.FillProperty, Theme.switchOnMouseOverBackgroundBrush, "outline"));
            isOnMouseOverTrigger.Setters.Add(new Setter(Shape.StrokeProperty, Theme.switchOnMouseOverBackgroundBrush, "outline"));

            var ct = new ControlTemplate(typeof(ButtonBase)){
                VisualTree = root,
            };
            ct.Triggers.Add(isOnTrigger);
            ct.Triggers.Add(mouseOverTrigger);
            ct.Triggers.Add(isOnMouseOverTrigger);
            ct.Triggers.Add(renderWithOnTrigger);

            var style = new Style(typeof(ButtonBase));
            style.Setters.Add(new Setter(Control.TemplateProperty, ct));
            return style;
        }

        protected override void OnClick()
        {
            IsOn = !IsOn;
        }
    }

    public class CustomTextBlock : TextBlock
    {
        public int GridRow
        {
            set { Grid.SetRow(this, value); }
        }

        public int GridColumn
        {
            set { Grid.SetColumn(this, value); }
        }

        public CustomTextBlock(string bindingName, string bindingFormat = null)
        {
            SetBinding(TextBlock.TextProperty, new OneWayBinding(bindingName){
                StringFormat = bindingFormat
            });

            Foreground = Theme.foregroundBrush;
            FontSize = 14.5;
            Margin = new Thickness{ Left = 25, Right = 25 };
            TextAlignment = TextAlignment.Left;
            TextWrapping = TextWrapping.Wrap;

            Typography.SlashedZero= true;
            VerticalAlignment = VerticalAlignment.Center;
        }
    }

    internal class OneWayBinding : Binding
    {
        internal OneWayBinding(string path) :base(path)
        {
            Mode = BindingMode.OneWay;
            UpdateSourceTrigger = UpdateSourceTrigger.PropertyChanged;
            ConverterCulture = CultureInfo.CurrentUICulture;
        }
    }

    internal class TwoWayBinding : Binding
    {
        internal TwoWayBinding(string path) :base(path)
        {
            Mode = BindingMode.TwoWay;
            UpdateSourceTrigger = UpdateSourceTrigger.PropertyChanged;
            ConverterCulture = CultureInfo.CurrentUICulture;
        }
    }

    public class DelegateCommand : ICommand
    {
        public Action<object> ExecuteHandler { get; set; }
        public Func<object, bool> CanExecuteHandler { get; set; }
        public event EventHandler CanExecuteChanged;

        public bool CanExecute(object parameter)
        {
            if (CanExecuteHandler == null) { return true; }
            return CanExecuteHandler(parameter);
        }

        public void Execute(object parameter)
        {
            if (ExecuteHandler != null)
                ExecuteHandler.Invoke(parameter);
        }

        public void RaiseCanExecuteChanged()
        {
            if (CanExecuteChanged != null)
                CanExecuteChanged.Invoke(this, EventArgs.Empty);
        }
    }

    internal static class Extensions
    {
        internal static BeginStoryboard ToBegin(this Storyboard storyboard)
        {
            return new BeginStoryboard{ Storyboard = storyboard };
        }

        internal static Storyboard ToStoryboard(
            this Timeline animation,
            string targetName,
            PropertyPath targetProperty
        ){
            Storyboard.SetTargetName(animation, targetName);
            Storyboard.SetTargetProperty(animation, targetProperty);

            var storyboard = new Storyboard();
            storyboard.Children.Add(animation);
            return storyboard;
        }

        internal static Storyboard ToStoryboard(
            this Timeline animation,
            DependencyObject target,
            PropertyPath targetProperty
        ){
            Storyboard.SetTarget(animation, target);
            Storyboard.SetTargetProperty(animation, targetProperty);

            var storyboard = new Storyboard();
            storyboard.Children.Add(animation);
            return storyboard;
        }
    }

    public class Snackbar : HeaderedContentControl
    {
        public int GridRow
        { set { Grid.SetRow(this, value); } }

        public int GridColumn
        { set { Grid.SetColumn(this, value); } }

        public int GridRowSpan
        { set { Grid.SetRowSpan(this, value); } }

        public int GridColumnSpan
        { set { Grid.SetColumnSpan(this, value); } }

        public bool RequestVisible
        {
            get { return (bool)GetValue(RequestVisibleProperty); }
            set { SetValue(RequestVisibleProperty, value); }
        }
        private static PropertyPath positionPropertyPath = new PropertyPath(
            "(0).(1)",
            UIElement.RenderTransformProperty,
            TranslateTransform.YProperty
        );
        public static readonly DependencyProperty RequestVisibleProperty =
            DependencyProperty.Register(
                "RequestVisible",
                typeof(bool),
                typeof(Snackbar),
                new PropertyMetadata(false, RequestVisible_PropertyChanged)
            );

        private static void RequestVisible_PropertyChanged(DependencyObject d, DependencyPropertyChangedEventArgs e)
        {
            if ((bool)e.OldValue != (bool)e.NewValue) {
                var dpObj = d as Snackbar;
                switch ((bool)e.NewValue)
                {
                    case true:
                        dpObj.Visibility = Visibility.Visible;
                        dpObj._visibleStoryboard.Begin();
                        break;
                    case false:
                        dpObj._hideStoryboard.Begin();
                        break;
                }
            }
        }

        private Storyboard _visibleStoryboard;
        private Storyboard _hideStoryboard;

        public Snackbar()
        {
            RenderTransform = new TranslateTransform(0, -200);
            Visibility = Visibility.Collapsed;

            var enterAnimation = new DoubleAnimation{
                Duration = TimeSpan.FromMilliseconds(500),
                To = 40,
                EasingFunction = new QuarticEase{ EasingMode = EasingMode.EaseOut },
            };
            _visibleStoryboard = enterAnimation.ToStoryboard(this, positionPropertyPath);

            var exitAnimation = new DoubleAnimation{
                Duration = TimeSpan.FromMilliseconds(500),
                BeginTime = TimeSpan.FromMilliseconds(400),
                To = -200.0,
                EasingFunction = new CircleEase{ EasingMode = EasingMode.EaseIn }
            };
            exitAnimation.Completed += (sender, e) => { Visibility = Visibility.Collapsed; };
            _hideStoryboard = exitAnimation.ToStoryboard(this, positionPropertyPath);

            Background = Theme.snackbarBackgroundBrush;

            Style = CreateStyle();
        }

        private static Style CreateStyle()
        {
            var header = new FrameworkElementFactory(typeof(ContentPresenter), "Header");
            header.SetValue(FrameworkElement.VerticalAlignmentProperty, VerticalAlignment.Center);
            header.SetValue(FrameworkElement.HorizontalAlignmentProperty, HorizontalAlignment.Center);
            header.SetValue(ContentPresenter.ContentSourceProperty, "Header");
            header.SetValue(Grid.ColumnProperty, 0);

            var content = new FrameworkElementFactory(typeof(ContentPresenter), "Content");
            content.SetValue(Grid.ColumnProperty, 1);

            var row0 = new FrameworkElementFactory(typeof(RowDefinition));
            row0.SetValue(RowDefinition.HeightProperty, new GridLength(40.0));

            var column0 = new FrameworkElementFactory(typeof(ColumnDefinition));
            column0.SetValue(ColumnDefinition.WidthProperty, GridLength.Auto);
            column0.SetValue(ColumnDefinition.MinWidthProperty, 40.0);

            var column1 = new FrameworkElementFactory(typeof(ColumnDefinition));
            column1.SetValue(ColumnDefinition.WidthProperty, new GridLength(1.0, GridUnitType.Star));

            var grid = new FrameworkElementFactory(typeof(Grid), "Grid");
            grid.AppendChild(row0);
            grid.AppendChild(column0);
            grid.AppendChild(column1);
            grid.AppendChild(header);
            grid.AppendChild(content);

            var root = new FrameworkElementFactory(typeof(Border), "TemplateRoot");
            root.SetValue(Control.BackgroundProperty, new TemplateBindingExtension(Control.BackgroundProperty));
            root.SetValue(FrameworkElement.HorizontalAlignmentProperty, HorizontalAlignment.Center);
            root.SetValue(Border.CornerRadiusProperty, new CornerRadius(20));
            root.SetValue(UIElement.EffectProperty, new DropShadowEffect{ BlurRadius = 6.0, Opacity = 0.3 });
            root.AppendChild(grid);

            var ct = new ControlTemplate(typeof(Snackbar)){
                VisualTree = root,
            };

            var style = new Style(typeof(Snackbar));
            style.Setters.Add(new Setter(Control.TemplateProperty, ct));
            return style;
        }
    }

    public class LoadingMessage : Snackbar
    {
        public LoadingMessage()
        {
            Header = new CustomSpinner();
            Content =  new CustomTextBlock("BusyMessage"){ FontFamily = SystemFonts.MessageFontFamily };
        }
    }

    public class CompleteMessage : Snackbar
    {
        public CompleteMessage()
        {
            Header = new System.Windows.Shapes.Path{
                Data = Theme.completedGeometry,
                Fill = Theme.completedIconBrush,
                Width = 25,
                Height = 25,
                Stretch = Stretch.Uniform
            };

            var openButton = new TileButton(
                new System.Windows.Shapes.Path{
                    Data = Theme.playGeometry,
                    Fill = Theme.foregroundBrush
                }
            ){
                Margin = new Thickness{ Right = 25 }
            };
            openButton.SetBinding(ButtonBase.CommandProperty, new OneWayBinding("OpenFileCommand"));

            var stack = new StackPanel{
                Orientation = Orientation.Horizontal,
            };

            stack.Children.Add(new CustomTextBlock("CompleteMessage"){
                FontFamily = SystemFonts.MessageFontFamily,
                Margin = new Thickness{ Left = 10, Right = 10 }
            });
            stack.Children.Add(openButton);

            Content = stack;
        }
    }

    public class CustomSpinner : UserControl
    {
        public Shape ArcRight { get; set; }
        public Shape ArcLeft { get; set; }
        public Canvas Spinner { get; set; }
        
        public int GridColumn { set { Grid.SetColumn(this, value); } }
        public int GridRow { set { Grid.SetRow(this, value); } }
        public bool IsSpinning
        {
            get { return (bool)GetValue(IsSpinningProperty); }
            set { SetValue(IsSpinningProperty, value); }
        }
        public static readonly DependencyProperty IsSpinningProperty =
            DependencyProperty.Register("IsSpinning", typeof(bool), typeof(CustomSpinner),
                                        new PropertyMetadata(false, IsSpinning_PropertyChanged));

        private static void IsSpinning_PropertyChanged(DependencyObject d, DependencyPropertyChangedEventArgs e)
        {
            if ((bool)e.OldValue != (bool)e.NewValue)
                switch ((bool)e.NewValue)
                {
                    case true:
                        ((CustomSpinner)d)._spinnerStoryboard.Begin();
                        ((CustomSpinner)d)._arcStoryboard.Begin();
                        break;
                    case false:
                        ((CustomSpinner)d)._spinnerStoryboard.Stop();
                        break;
                }
        }

        private Storyboard _spinnerStoryboard;
        private Storyboard _arcStoryboard;

        public CustomSpinner()
        {
            Height = 25;
            Width = 25;
            InitializeComponent();
            IsVisibleChanged += (sender, e) => {
                IsSpinning = IsVisible;
            };
        }

        private void InitializeComponent()
        {
            var circle = new System.Windows.Shapes.Path {
                Data = Geometry.Parse("M 50 1 A 49 49 90 0 0 50 99 A 49 49 90 0 0 50 1 Z M 50 14 A 35.5 35.5 90 0 1 50 86 A 35.5 35.5 90 0 1 50 14 Z"),
                Fill = Theme.spinnerBackgroundBrush,
                UseLayoutRounding = false
            };

            ArcLeft = new System.Windows.Shapes.Path {
                Data = Geometry.Parse("M 50 0 A 50 50 0 0 0 50 100 L 50 85 A 35 35 0 0 1 50 15 Z"),
                RenderTransform = new RotateTransform(180, 50, 50),
                Fill = Theme.spinnerForegroundBrush,
                UseLayoutRounding = false,
            };

            ArcRight = new System.Windows.Shapes.Path {
                Data = Geometry.Parse("M -0 100 A 50 50 -180 0 0 0 -0 L -0 15 A 35 35 -180 0 1 -0 85 Z"),
                RenderTransform = new RotateTransform(180, 0, 50),
                Fill = Theme.spinnerForegroundBrush,
                UseLayoutRounding = false
            };

            var arcLeftAnimation1 = new DoubleAnimation{
                Duration = TimeSpan.FromMilliseconds(600),
                From = 180.0,
                To = 360.0,
            };
            var arcLeftAnimation2 = new DoubleAnimation{
                Duration = TimeSpan.FromMilliseconds(400),
                From = 0.0,
                To = 180.0,
            };
            var arcRightAnimation1 = new DoubleAnimation{
                Duration = TimeSpan.FromMilliseconds(600),
                From = 180.0,
                To = 360.0,
            };
            var arcRightAnimation2 = new DoubleAnimation{
                Duration = TimeSpan.FromMilliseconds(400),
                From = 0.0,
                To = 180.0
            };

            Storyboard arcLeftStoryboard1 = arcLeftAnimation1.ToStoryboard(ArcLeft, rotatePropertyPath);
            Storyboard arcLeftStoryboard2 = arcLeftAnimation2.ToStoryboard(ArcLeft, rotatePropertyPath);
            Storyboard arcRightStoryboard1 = arcRightAnimation1.ToStoryboard(ArcRight, rotatePropertyPath);
            Storyboard arcRightStoryboard2 = arcRightAnimation2.ToStoryboard(ArcRight, rotatePropertyPath);

            _arcStoryboard = arcLeftStoryboard1;

            arcLeftAnimation1.Completed += (sender, e) => { if (IsSpinning) arcRightStoryboard1.Begin(this); };
            arcLeftAnimation2.Completed += (sender, e) => { arcRightStoryboard2.Begin(this); };
            arcRightAnimation1.Completed += (sender, e) => { arcLeftStoryboard2.Begin(this); };
            arcRightAnimation2.Completed += (sender, e) => { arcLeftStoryboard1.Begin(this); };

            var arcLeftBorder = new Border{
                Child = ArcLeft,
                ClipToBounds = true,
                Width = 50,
                Height = 100
            };

            var arcRightBorder = new Border{
                Child = ArcRight,
                ClipToBounds = true,
                Width = 50,
                Height = 100
            };
            Canvas.SetLeft(arcRightBorder, 49);
            
            Spinner = new Canvas{
                RenderTransform = new RotateTransform(0, 50, 50),
                UseLayoutRounding = false,
                Width = 100,
                Height = 100
            };

            var spinnerAnimation = new DoubleAnimationUsingKeyFrames{
                Duration = TimeSpan.FromMilliseconds(9000),
                RepeatBehavior = RepeatBehavior.Forever
            };
            spinnerAnimation.KeyFrames.Add(new SplineDoubleKeyFrame(480, KeyTime.FromPercent(0.33), new KeySpline(0.4, 0.6, 0.7, 0.3)));
            spinnerAnimation.KeyFrames.Add(new SplineDoubleKeyFrame(960, KeyTime.FromPercent(0.66), new KeySpline(0.4, 0.6, 0.7, 0.3)));
            spinnerAnimation.KeyFrames.Add(new SplineDoubleKeyFrame(1440, KeyTime.FromPercent(1.0), new KeySpline(0.4, 0.6, 0.7, 0.3)));
            _spinnerStoryboard = spinnerAnimation.ToStoryboard(Spinner, rotatePropertyPath);

            Spinner.Children.Add(circle);
            Spinner.Children.Add(arcLeftBorder);
            Spinner.Children.Add(arcRightBorder);

            var viewbox = new Viewbox{
                Child = Spinner,
            };

            Content = viewbox;
        }

        private static PropertyPath rotatePropertyPath = new PropertyPath(
            "(0).(1)",
            UIElement.RenderTransformProperty,
            RotateTransform.AngleProperty
        );
    }

    public class ViewModel : INotifyPropertyChanged
    {
        public event PropertyChangedEventHandler PropertyChanged = (sender, e) => { };

        private void NotifyPropertyChanged([CallerMemberName] string propertyName = "")
        {
            PropertyChanged.Invoke(this, new PropertyChangedEventArgs(propertyName));
        }

        private double _progress = 0.0 ;
        public double Progress
        {
            get { return _progress; }
            set
            {
                if (_progress < value)
                {
                    _progress = value;
                    NotifyPropertyChanged();
                }
            }
        }

        private ProgressStatus _progressStatus = ProgressStatus.Initialize;
        public ProgressStatus ProgressStatus
        {
            get { return _progressStatus; }
            set {
                if (_progressStatus != value) {
                    _progressStatus = value;
                    NotifyPropertyChanged();
                }
            }
        }

        private string _progressLabel = String.Empty;
        public string ProgressLabel
        {
            get { return _progressLabel; }
            set { _progressLabel = value; NotifyPropertyChanged(); }
        }

        private string _statusDescription = String.Empty;
        public string StatusDescription
        {
            get { return _statusDescription; }
            set { _statusDescription = value; NotifyPropertyChanged(); }
        }

        private TimeSpan _progressRemaining;
        public TimeSpan ProgressRemaining
        {
            get { return _progressRemaining; }
            set { _progressRemaining = value; NotifyPropertyChanged(); }
        }

        private string _currentOperation;
        public string CurrentOperation
        {
            get { return _currentOperation; }
            set { _currentOperation = value; NotifyPropertyChanged();}
        }

        private bool _autoClose = false;
        public bool AutoClose
        {
            get { return _autoClose; }
            set { _autoClose = value; NotifyPropertyChanged(); }
        }

        private string _autoCloseText = "Automatically close GUI window.";
        public string AutoCloseText
        {
            get { return _autoCloseText; }
            set { _autoCloseText = value; NotifyPropertyChanged(); }
        }

        private bool _autoPlay = false;
        public bool AutoPlay
        {
            get { return _autoPlay; }
            set { _autoPlay = value; NotifyPropertyChanged(); }
        }

        private string _autoPlayText = "Automatically play output video after encoding.";
        public string AutoPlayText
        {
            get { return _autoPlayText; }
            set { _autoPlayText = value; NotifyPropertyChanged(); }
        }

        private bool _openExplorer = false;
        public bool OpenExplorer
        {
            get { return _openExplorer; }
            set { _openExplorer = value; NotifyPropertyChanged(); }
        }

        private string _openExplorerText = "Open the folder containing the encoded file.";
        public string OpenExplorerText
        {
            get { return _openExplorerText; }
            set { _openExplorerText = value; NotifyPropertyChanged(); }
        }

        private bool _windowTopmost = true;
        public bool WindowTopmost
        {
            get { return _windowTopmost; }
            set { _windowTopmost = value; NotifyPropertyChanged(); }
        }

        private bool _busy = true;
        public bool Busy
        {
            get { return _busy; }
            set {
                if (_busy != value) {
                    _busy = value;
                    NotifyPropertyChanged();
                }
            }
        }

        private string _busyMessage = "Loading.";
        public string BusyMessage
        {
            get { return _busyMessage; }
            set { _busyMessage = value; NotifyPropertyChanged(); }
        }

        private string _completeMessage = "Encoding completed.";
        public string CompleteMessage
        {
            get { return _completeMessage; }
            set { _completeMessage = value; NotifyPropertyChanged(); }
        }

        private ICommand _topmostCommand;
        public ICommand TopmostCommand
        {
            get
            {
                if (_topmostCommand == null)
                    _topmostCommand = new DelegateCommand{
                        ExecuteHandler = (param) => {
                            if (param is bool)
                                WindowTopmost = (bool)param;
                        },
                    };
                return _topmostCommand;
            }
        }

        private WindowState _windowState = WindowState.Normal;
        public WindowState WindowState
        {
            get { return _windowState; }
            set { _windowState = value; NotifyPropertyChanged(); }
        }

        private string _windowTitle = "Progress";
        public string WindowTitle
        {
            get { return _windowTitle; }
            set { _windowTitle = value; NotifyPropertyChanged(); }
        }

        private ICommand _minimiseCommand;
        public ICommand MinimiseCommand
        {
            get
            {
                if (_minimiseCommand == null)
                    _minimiseCommand = new DelegateCommand{
                        ExecuteHandler = (param) => {
                            WindowState = WindowState.Minimized;
                        },
                    };
                return _minimiseCommand;
            }
        }

        private ICommand _showPromptCommand;
        public ICommand ShowPromptCommand
        {
            get { return _showPromptCommand; }
            set { _showPromptCommand = value; NotifyPropertyChanged(); }
        }

        private ICommand _processControlCommand;
        public ICommand ProcessControlCommand
        {
            get { return _processControlCommand; }
            set { _processControlCommand = value; NotifyPropertyChanged(); }
        }

        private ICommand _processExitCommand;
        public ICommand ProcessExitCommand
        {
            get { return _processExitCommand; }
            set { _processExitCommand = value; NotifyPropertyChanged(); }
        }

        private ICommand _openFolderCommand;
        public ICommand OpenFolderCommand
        {
            get { return _openFolderCommand; }
            set { _openFolderCommand = value; NotifyPropertyChanged(); }
        }

        private ICommand _openFileCommand;
        public ICommand OpenFileCommand
        {
            get { return _openFileCommand; }
            set { _openFileCommand = value; NotifyPropertyChanged(); }
        }

        public ViewModel() 
        { }
    }

    public class CustomProgressBar : ProgressBar
    {
        private bool _smoothValueActive = false;
        public double SmoothValue
        {
            get { return (double)GetValue(SmoothValueProperty); }
            set { SetValue(SmoothValueProperty, value); }
        }

        public static readonly DependencyProperty SmoothValueProperty =
            DependencyProperty.RegisterAttached("SmoothValue", typeof(double), typeof(CustomProgressBar), new PropertyMetadata(0.0, SmoothValue_PropertyChanged));

        private static void SmoothValue_PropertyChanged(DependencyObject d, DependencyPropertyChangedEventArgs e)
        {
            var source = d as CustomProgressBar;
            if (source.IsActive) {
                var anim = new DoubleAnimation((double)e.NewValue, TimeSpan.FromMilliseconds(500));
                anim.Completed += (s, _) => { source._smoothValueActive = false; };
                source.BeginAnimation(ProgressBar.ValueProperty, anim, HandoffBehavior.Compose);
                source._smoothValueActive = true;
            }
        }

        public Transform StripeTransform
        {
            get { return (Transform)GetValue(StripeTransformProperty); }
            set { SetValue(StripeTransformProperty, value); }
        }
        public static readonly DependencyProperty StripeTransformProperty =
            DependencyProperty.RegisterAttached("StripeTransform", typeof(Transform), typeof(CustomProgressBar), new PropertyMetadata(new TranslateTransform()));

        private DrawingBrush _stripeBrush;
        public DrawingBrush StripeBrush
        {
            get {
                if (_stripeBrush == null)
                    _stripeBrush = CreateStripeBrush();
                
                return _stripeBrush;
            }
            set { _stripeBrush = value; }
        }

        private DoubleAnimation _progressBarStripeAnimation = new DoubleAnimation{
            From = 0.0,
            To = 40.0,
            RepeatBehavior = RepeatBehavior.Forever,
            Duration = new Duration(TimeSpan.FromMilliseconds(500.0))
        };

        private Storyboard _progressAnimationStoryboard;
        
        public bool IsActive
        {
            get { return (bool)GetValue(IsActiveProperty); }
            set { SetValue(IsActiveProperty, value); }
        }
        public static readonly DependencyProperty IsActiveProperty =
            DependencyProperty.Register("IsActive", typeof(bool), typeof(CustomProgressBar),
                                        new PropertyMetadata(false, new PropertyChangedCallback(IsActive_PropertyChanged)));

        public string LabelText
        {
            get { return (string)GetValue(LabelTextProperty); }
            set { SetValue(LabelTextProperty, value); }
        }

        public static readonly DependencyProperty LabelTextProperty =
            DependencyProperty.Register("LabelText", typeof(string), typeof(CustomProgressBar),
                                        new PropertyMetadata(String.Empty));

        public int GridRow
        {
            set { Grid.SetRow(this, value); }
        }

        public int GridColumn
        {
            set { Grid.SetColumn(this, value); }
        }

        public CustomProgressBar()
        {
            _progressAnimationStoryboard = _progressBarStripeAnimation.ToStoryboard(
                this,
                new PropertyPath(
                    "(0).(1)",
                    CustomProgressBar.StripeTransformProperty,
                    TranslateTransform.XProperty
                )
            );

            Height = 30;
            Width = 600;
            Minimum = 0.0;
            Maximum = 100.0;
            Margin = new Thickness{ Left = 20, Right = 20 };
            VerticalAlignment = VerticalAlignment.Center;
            Template = CreateTemplate();

            BeginProgressAnimation();
        }

        private static async void IsActive_PropertyChanged(DependencyObject d, DependencyPropertyChangedEventArgs e)
        {
            CustomProgressBar source = (CustomProgressBar)d;
            if ((bool)e.OldValue == (bool)e.NewValue) { return; }

            switch ((bool)e.NewValue)
            {
                case true:
                    source.ResumeProgressAnimation();
                    break;
                case false:
                    for(int l = 50; l > 0; l++) {
                        if (source._smoothValueActive == false) {
                            source.PauseProgressAnimation();
                            break;
                        } else {
                            await Task.Delay(100);
                        }
                    }
                    break;
            }
        }

        private static ControlTemplate CreateTemplate()
        {
            var indicator = new FrameworkElementFactory(typeof(Rectangle), "Indicator");
            indicator.SetValue(Shape.FillProperty, Theme.progressBarFgBrush);

            var stripe = new FrameworkElementFactory(typeof(Rectangle), "Stripe");
            stripe.SetBinding(
                Shape.FillProperty,
                new Binding("StripeBrush"){ RelativeSource = RelativeSource.TemplatedParent }
            );

            var partIndicator = new FrameworkElementFactory(typeof(Grid), "PART_Indicator");
            partIndicator.SetValue(UIElement.RenderTransformOriginProperty, new Point(0, 1));
            partIndicator.SetValue(UIElement.RenderTransformProperty, new SkewTransform(-45, 0));
            partIndicator.SetValue(FrameworkElement.HorizontalAlignmentProperty, HorizontalAlignment.Left);
            partIndicator.SetValue(FrameworkElement.MarginProperty, new Thickness{ Left = -30.0,  Right = 10.0 });
            partIndicator.AppendChild(indicator);
            partIndicator.AppendChild(stripe);

            var partTrack = new FrameworkElementFactory(typeof(Border), "PART_Track");
            partTrack.SetValue(Border.BackgroundProperty, Theme.progressBarBgBrush);
            partTrack.SetValue(UIElement.ClipToBoundsProperty, true);
            partTrack.SetValue(UIElement.SnapsToDevicePixelsProperty, true);
            partTrack.AppendChild(partIndicator);

            var percentageLabel = new FrameworkElementFactory(typeof(Label));
            percentageLabel.SetBinding(
                ContentControl.ContentProperty,
                new Binding("Value"){ RelativeSource = RelativeSource.TemplatedParent }
            );
            percentageLabel.SetValue(ContentControl.ContentStringFormatProperty, "{0:N1} %");
            percentageLabel.SetValue(FrameworkElement.HorizontalAlignmentProperty, HorizontalAlignment.Right);
            percentageLabel.SetValue(FrameworkElement.VerticalAlignmentProperty, VerticalAlignment.Center);
            percentageLabel.SetValue(TextBlock.FontStyleProperty, FontStyles.Italic);
            percentageLabel.SetValue(TextBlock.ForegroundProperty, Theme.foregroundBrush);
            percentageLabel.SetValue(FrameworkElement.MarginProperty, new Thickness{ Right = 60.0 });

            var progressLabel = new FrameworkElementFactory(typeof(Label));
            progressLabel.SetBinding(
                ContentControl.ContentProperty,
                new Binding("LabelText"){ RelativeSource = RelativeSource.TemplatedParent }
            );
            progressLabel.SetValue(Control.FontFamilyProperty, new FontFamily("Yu Gothic UI Semibold"));
            progressLabel.SetValue(Control.FontSizeProperty, 14.0);
            progressLabel.SetValue(FrameworkElement.HorizontalAlignmentProperty, HorizontalAlignment.Left);
            progressLabel.SetValue(FrameworkElement.VerticalAlignmentProperty, VerticalAlignment.Center);
            progressLabel.SetValue(TextBlock.ForegroundProperty, Theme.foregroundBrush);
            progressLabel.SetValue(FrameworkElement.MarginProperty, new Thickness{ Left = 10.0 });

            var root = new FrameworkElementFactory(typeof(Grid), "TemplateRoot");
            root.AppendChild(partTrack);
            root.AppendChild(percentageLabel);
            root.AppendChild(progressLabel);

            var controlTemplate = new ControlTemplate(typeof(ProgressBar)){
                VisualTree = root
            };

            var completedTrigger = new Trigger{
                Property = RangeBase.ValueProperty,
                Value = 100.0,
            };
            completedTrigger.Setters.Add(new Setter(UIElement.VisibilityProperty, Visibility.Collapsed, "Stripe"));
            completedTrigger.Setters.Add(new Setter(Shape.FillProperty, Theme.progressBarCompletedBrush, "Indicator"));
            controlTemplate.Triggers.Add(completedTrigger);

            return controlTemplate;
        }

        private DrawingBrush CreateStripeBrush()
        {
            var stripeBrush = new DrawingBrush{
                TileMode = TileMode.Tile,
                Stretch = Stretch.Uniform,
                Viewport = new Rect(0, 0, 40, 20),
                ViewportUnits = BrushMappingMode.Absolute,
                Transform = StripeTransform
            };

            var geometryDrawing = new GeometryDrawing();
            geometryDrawing.Geometry = PathGeometry.Parse(
                "M 0,0 L 10,0 L 10,20 L 0,20 Z M 30,0 L 40,0 L 40,20 L 30,20 Z"
            );
            geometryDrawing.Brush = Theme.progressBarStripeBrush;
            stripeBrush.Drawing = geometryDrawing;

            return stripeBrush;
        }

        public void BeginProgressAnimation()
        {
            _progressAnimationStoryboard.Begin(this, true);
        }

        public void ResumeProgressAnimation()
        {
            _progressAnimationStoryboard.Resume(this);
        }

        public void PauseProgressAnimation()
        {
            _progressAnimationStoryboard.Pause(this);
        }
    }

    [Flags]
    public enum ProgressStatus
    {
        Initialize = 1,
        Processing = 2,
        Suspend = 4,
        Completed = 8
    }

    [ValueConversion(typeof(Enum), typeof(Boolean))]
    public class EnumToBooleanConverter : IValueConverter
    {
        public static EnumToBooleanConverter I = new EnumToBooleanConverter();

        public object Convert(object value, Type targetType, object parameter, System.Globalization.CultureInfo culture)
        {
            if (value == null || parameter == null)
                return Binding.DoNothing;

            bool? result = null;
            try {
                int status = (int)value;
                int param = (int)parameter;
                result = (status & param) == status;
            } catch (InvalidCastException) { }

            if (result != null)
                return result;
            else
                return Binding.DoNothing;
        }

        public object ConvertBack(object value, Type targetType, object parameter, System.Globalization.CultureInfo culture)
        {
            return Binding.DoNothing;
        }
    }

    [ValueConversion(typeof(Enum), typeof(Visibility))]
    public class EnumToVisibilityConverter : IValueConverter
    {
        public static EnumToVisibilityConverter I = new EnumToVisibilityConverter();
        public object Convert(object value, Type targetType, object parameter, System.Globalization.CultureInfo culture)
        {
            if (value == null || parameter == null)
                return Binding.DoNothing;

            bool? result = null;
            try {
                int status = (int)value;
                int param = (int)parameter;
                result = (status & param) == status;
            } catch (InvalidCastException) { }

            switch (result) {
                case false:
                    return Visibility.Collapsed;
                case true:
                    return Visibility.Visible;
                default:
                    return Binding.DoNothing;
            }
        }

        public object ConvertBack(object value, Type targetType, object parameter, System.Globalization.CultureInfo culture)
        {
            return Binding.DoNothing;
        }
    }

    [ValueConversion(typeof(ProgressStatus), typeof(TaskbarItemProgressState))]
    public class TaskbarItemProgressStateConverter : IValueConverter
    {
        public static TaskbarItemProgressStateConverter I = new TaskbarItemProgressStateConverter();
        public object Convert(object value, Type targetType, object parameter, System.Globalization.CultureInfo culture)
        {
            if (value == null || !(value is ProgressStatus))
                return Binding.DoNothing;

            switch ((ProgressStatus)value) {
                case ProgressStatus.Initialize:
                    return TaskbarItemProgressState.Indeterminate;
                case ProgressStatus.Processing:
                    return TaskbarItemProgressState.Normal;
                case ProgressStatus.Suspend:
                    return TaskbarItemProgressState.Paused;
                case ProgressStatus.Completed:
                    return TaskbarItemProgressState.None;
                default :
                    return Binding.DoNothing;
            }
        }

        public object ConvertBack(object value, Type targetType, object parameter, System.Globalization.CultureInfo culture)
        {
            return Binding.DoNothing;
        }
    }
}

namespace DropWindow
{
    internal class Theme
    {
        internal static Color backgroundColor = new Color { A = 255, R = 40, G = 40, B = 40 };
        internal static Brush backgroundBrush = new SolidColorBrush(backgroundColor);
        internal static Brush foregroundBrush = new SolidColorBrush(Colors.WhiteSmoke);

        internal static Color dashedBorderColor = new Color { A = 255, R = 60, G = 60, B = 60 };
        internal static Brush dashedBorderBrush = new SolidColorBrush(dashedBorderColor);

        static Theme()
        { }
    }

    public class MainWindow : Window
    {
        private DragDropText _dragDropText = new DragDropText();

        public MainWindow(string caption)
        {
            Title = caption;
            Width = 480.0;
            Height = 270.0;
            ShowActivated = true;
            WindowStartupLocation = WindowStartupLocation.Manual;
            Top = 150.0;
            Left = 150.0;
            Topmost = true;
            Background = Theme.backgroundBrush;
            ResizeMode = ResizeMode.NoResize;
            AllowDrop = true;

            InitializeComponent();
        }

        private void InitializeComponent()
        {
            var mainGrid = new Grid();
            mainGrid.Children.Add(_dragDropText);
            Content = mainGrid;
        }
    }

    internal class DragDropText : ContentControl
    {
        private TextBlock _textBlock;

        private Brush _stroke;
        private double _strokeThickness;
        private double _strokeDashLine;
        private double _strokeDashSpace;
        private Brush _Fill;

        public DragDropText()
        {

            _textBlock = new TextBlock
            {
                Text = "Drag & Drop here",
                Background = Brushes.Transparent,
                Foreground = Theme.foregroundBrush,
                HorizontalAlignment = HorizontalAlignment.Center,
                VerticalAlignment = VerticalAlignment.Center,
                TextAlignment = TextAlignment.Center,
                FontSize = 23.0,
                Margin = new Thickness(5.0),
            };

            SnapsToDevicePixels = true;
            UseLayoutRounding = true;
            Margin = new Thickness(15.0);

            _stroke = Theme.dashedBorderBrush;
            _strokeThickness = 4.0;
            _strokeDashLine = 10.0;
            _strokeDashSpace = 10.0;
            _Fill = Brushes.Transparent;

            Content = _textBlock;
        }

        protected override void OnRender(DrawingContext drawingContext)
        {
            double w = ActualWidth;
            double h = ActualHeight;
            double x = _strokeThickness / 2.0;

            Pen horizontalPen = GetPen(ActualWidth - 2.0 * x);
            Pen verticalPen = GetPen(ActualHeight - 2.0 * x);

            drawingContext.DrawRectangle(_Fill, null, new Rect(new Point(0, 0), new Size(w, h)));

            drawingContext.DrawLine(horizontalPen, new Point(x, x), new Point(w - x, x));
            drawingContext.DrawLine(horizontalPen, new Point(x, h - x), new Point(w - x, h - x));

            drawingContext.DrawLine(verticalPen, new Point(x, x), new Point(x, h - x));
            drawingContext.DrawLine(verticalPen, new Point(w - x, x), new Point(w - x, h - x));
        }

        private Pen GetPen(double length)
        {
            IEnumerable<double> dashArray = GetDashArray(length);
            return new Pen(_stroke, _strokeThickness)
            {
                DashStyle = new DashStyle(dashArray, 0),
                EndLineCap = PenLineCap.Square,
                StartLineCap = PenLineCap.Square,
                DashCap = PenLineCap.Flat
            };
        }

        private IEnumerable<double> GetDashArray(double length)
        {
            double useableLength = length - _strokeDashLine;
            int lines = (int)Math.Round(useableLength / (_strokeDashLine + _strokeDashSpace));
            useableLength -= lines * _strokeDashLine;
            double actualSpacing = useableLength / lines;

            yield return _strokeDashLine / _strokeThickness;
            yield return actualSpacing / _strokeThickness;
        }
    }
}

namespace HelperClasses
{
    internal class SafeThreadHandle : SafeHandleZeroOrMinusOneIsInvalid
    {
        [DllImport("kernel32", SetLastError = true)]
        [ReliabilityContract(Consistency.WillNotCorruptState, Cer.MayFail)]
        internal extern static bool CloseHandle(IntPtr handle);

        private SafeThreadHandle()
            : base(true)
        { }

        [ReliabilityContract(Consistency.WillNotCorruptState, Cer.MayFail)]
        override protected bool ReleaseHandle()
        {
            return CloseHandle(handle);
        }
    }

    public class WindowHelper
    {

        [DllImport("user32.dll")]
        private static extern bool ShowWindowAsync(IntPtr hWnd, int nCmdShow);

        [DllImport("user32.dll")]
        private static extern bool SetForegroundWindow(IntPtr hWnd);

        private const int SW_HIDE = 0;
        private const int SW_SHOW = 5;

        private IntPtr _hWnd = IntPtr.Zero;

        public WindowHelper(string windowTitle)
        {
            Process[] localAll = Process.GetProcesses();
            try {
                var targetProcess = localAll.Where(p => p.MainWindowTitle == windowTitle).First();
                _hWnd = targetProcess.MainWindowHandle;
            } catch (Exception e) {
                Debug.WriteLine(e);
            }
        }

        public void HideConsole()
        {
            if (_hWnd != IntPtr.Zero) {
                ShowWindowAsync(_hWnd, SW_HIDE);
            }
        }

        public void ShowConsole(bool activate = true)
        {
            if (_hWnd != IntPtr.Zero) {
                ShowWindowAsync(_hWnd, SW_SHOW);
                
                if (activate)
                    SetForegroundWindow(_hWnd);
            }
        }
    }

    public class ReceivedData
    {
        public enum DataType
        {
            StdOut,
            StdError,
        }

        public string Data { get; private set; }
        public DataType Type { get; private set; }

        public ReceivedData(string data, DataType type)
        {
            Data = data;
            Type = type;
        }

        private ReceivedData() { }

        public ReceivedData Empty
        {
            get { return new ReceivedData(); }
        }
    }

    public class ProcessInfo : IDisposable
    {
        [Flags]
        public enum ThreadAccess : int
        {
            TERMINATE = (0x0001),
            SUSPEND_RESUME = (0x0002),
            GET_CONTEXT = (0x0008),
            SET_CONTEXT = (0x0010),
            SET_INFORMATION = (0x0020),
            QUERY_INFORMATION = (0x0040),
            SET_THREAD_TOKEN = (0x0080),
            IMPERSONATE = (0x0100),
            DIRECT_IMPERSONATION = (0x0200)
        }

        [DllImport("kernel32.dll")]
        static extern SafeThreadHandle OpenThread(ThreadAccess dwDesiredAccess, bool bInheritHandle, uint dwThreadId);

        [DllImport("kernel32.dll", CharSet = CharSet.Auto,SetLastError = true)]
        static extern bool CloseHandle(IntPtr handle);
        [DllImport("kernel32.dll")]
        static extern uint SuspendThread(SafeThreadHandle hThread);
        [DllImport("kernel32.dll")]
        static extern int ResumeThread(SafeThreadHandle hThread);

        private bool _disposed = false;

        private const int MAX_QUE = 512;
        private ProcessStartInfo _startInfo;
        private TaskCompletionSource<int> _eventHandled;
        private Process _process;

        public bool IsSuspended { get; private set; }

        public bool TryGetProcess(out Process process)
        {
            process = _process;
            return _process != null;
        }

        private BlockingCollection<ReceivedData> _receivedData = new BlockingCollection<ReceivedData>(new ConcurrentQueue<ReceivedData>(), MAX_QUE);

        public BlockingCollection<ReceivedData> ReceivedDataQueue
        {
            get { return _receivedData; }
        }
        public ProcessInfo(string filename, string argumentList, bool useShellExec = false, bool redirect = true)
        {
            _startInfo = new ProcessStartInfo
            {
                FileName = filename,
                Arguments = argumentList,
                UseShellExecute = useShellExec,
                RedirectStandardOutput = redirect,
                RedirectStandardError = redirect,
                RedirectStandardInput = redirect
            };

            IsSuspended = false;
        }

        public void Suspend()
        {
            if (IsSuspended) { return; }

            Process process;
            if (TryGetProcess(out process))
                foreach (ProcessThread thread in process.Threads)
                {
                    using (var pOpenThread = OpenThread(ThreadAccess.SUSPEND_RESUME, false, (uint)thread.Id))
                    {
                        if (pOpenThread != null && (!pOpenThread.IsInvalid))
                            SuspendThread(pOpenThread);
                    }
                }
            IsSuspended = true;
        }

        public void Resume()
        {
            if (!IsSuspended) { return; }

            Process process;
            if (TryGetProcess(out process))
                foreach (ProcessThread thread in process.Threads)
                {
                    using (var pOpenThread = OpenThread(ThreadAccess.SUSPEND_RESUME, false, (uint)thread.Id))
                    {
                        if (pOpenThread != null && (!pOpenThread.IsInvalid))
                            ResumeThread(pOpenThread);
                    }
                }
            IsSuspended = false;
        }

        public async Task<int> Start()
        {

            if (_disposed) { throw new ObjectDisposedException("\"Dispose\" has already been executed."); }

            _eventHandled = new TaskCompletionSource<int>();

            using (_process = new Process { StartInfo = _startInfo, EnableRaisingEvents = true })
            {
                try
                {
                    _process.OutputDataReceived += (sender, e) =>
                    {
                        Task.Run(() =>
                        {
                            if (!String.IsNullOrEmpty(e.Data))
                            {
                                _receivedData.TryAdd(
                                    new ReceivedData(
                                        e.Data,
                                        ReceivedData.DataType.StdOut
                                    ),
                                    System.Threading.Timeout.Infinite
                                );
                            }
                        });
                    };
                    _process.ErrorDataReceived += (sender, e) =>
                    {
                        Task.Run(() =>
                        {
                            if (!String.IsNullOrEmpty(e.Data))
                            {
                                _receivedData.TryAdd(
                                    new ReceivedData(
                                        e.Data,
                                        ReceivedData.DataType.StdError
                                    ),
                                    System.Threading.Timeout.Infinite
                                );
                            }
                        });
                    };
                    _process.Exited += (sender, e) =>
                    {
                        _receivedData.CompleteAdding();
                        _eventHandled.TrySetResult(_process.ExitCode);
                    };
                    _process.Start();
                    _process.BeginOutputReadLine();
                    _process.BeginErrorReadLine();
                    //_process.PriorityClass = ProcessPriorityClass.High;
                }
                catch (Exception e)
                {
                    throw e;
                }
                await _eventHandled.Task;
            }

            _process = null;
            return _eventHandled.Task.Result;
        }

        public void Dispose()
        {
            Dispose(disposing: true);
            GC.SuppressFinalize(this);
        }

        protected virtual void Dispose(bool disposing)
        {
            if (!this._disposed)
            {
                if (disposing)
                {
                    _receivedData.Dispose();
                }
                _disposed = true;
            }
        }
    }
}

public static class ConsoleHelper
{

    public static void WriteLine(object message, int beforLines = 0, int afterLines = 0)
    {
        string format = 
            String.Concat(Enumerable.Repeat(Environment.NewLine, beforLines)) +
            "{0}" + String.Concat(Enumerable.Repeat(Environment.NewLine, afterLines));

        string formattedMessage = String.Format(
            CultureInfo.CurrentUICulture, 
            format,
            message
        );
        Console.WriteLine(formattedMessage);
    }
    public static void Log(object message, int beforLines = 0, int afterLines = 0)
    {
        Console.ForegroundColor = ConsoleColor.Yellow;
        WriteLine(message, beforLines, afterLines);
        Console.ResetColor();
    }

    public static void Error(object message, int beforLines = 0, int afterLines = 0)
    {
        Console.ForegroundColor = ConsoleColor.Yellow;
        WriteLine(message, beforLines, afterLines);
        Console.ResetColor();
    }
}