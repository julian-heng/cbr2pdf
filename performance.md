# cbr2pdf - Performance
## Rationale
I wanted to see how much better the script runs in parallel, thus I conducted these tests. On two "machines", an Antergos virtual machine and a MacBook Pro 2015, I've run the script on 10 archives, recording down with the `time` command, how long it takes to convert:

 * 4 parallels
 * 4 parallels without spinner
 * 2 parallels
 * 2 parallels without spinner
 * 1 parallel
 * 1 parallel without spinner
 * No parallel
 * No parallel without spinner
 * No parallel with quiet mode

## Results
```sh
# Antergos VM

              `.-/::/-``                   julian@Antergos-VirtualBox 
            .-/osssssssso/.                -------------------------- 
           :osyysssssssyyys+-              OS: Antergos Linux x86_64 
        `.+yyyysssssssssyyyyy+.            Host: VirtualBox 1.2 
       `/syyyyyssssssssssyyyyys-`          Kernel: 4.14.7-1-ARCH 
      `/yhyyyyysss++ssosyyyyhhy/`          Uptime: 40 mins 
     .ohhhyyyyso++/+oso+syy+shhhho.        Packages: 746 
    .shhhhysoo++//+sss+++yyy+shhhhs.       Shell: fish 2.7.0 
   -yhhhhs+++++++ossso+++yyys+ohhddy:      Resolution: 1680x1050 
  -yddhhyo+++++osyyss++++yyyyooyhdddy-     DE: Xfce 
 .yddddhso++osyyyyys+++++yyhhsoshddddy`    WM: Xfwm4 
`odddddhyosyhyyyyyy++++++yhhhyosddddddo    WM Theme: Arc-Darker 
.dmdddddhhhhhhhyyyo+++++shhhhhohddddmmh.   Theme: Arc-Darker [GTK2], Numix-Frost-Light [GTK 
ddmmdddddhhhhhhhso++++++yhhhhhhdddddmmdy   Icons: Paper [GTK2], Numix-Square [GTK3] 
dmmmdddddddhhhyso++++++shhhhhddddddmmmmh   Terminal: xfce4-terminal 
-dmmmdddddddhhyso++++oshhhhdddddddmmmmd-   Terminal Font: Consolas 9 
.smmmmddddddddhhhhhhhhhdddddddddmmmms.     CPU: Intel i7-5557U (4) @ 3.099GHz 
   `+ydmmmdddddddddddddddddddmmmmdy/.      GPU: VirtualBox Graphics Adapter 
      `.:+ooyyddddddddddddyyso+:.`         Memory: 542MiB / 7984MiB 


# 4 Parallel, processing 10 files
97.29user 28.74system 0:58.95elapsed 213%CPU (0avgtext+0avgdata 1154408maxresident)k
0inputs+1076824outputs (0major+1499196minor)pagefaults 0swaps

# 4 Parallel, processing 10 files, no spinner
72.76user 8.74system 0:34.97elapsed 233%CPU (0avgtext+0avgdata 1154428maxresident)k
0inputs+1076824outputs (0major+543357minor)pagefaults 0swaps

# 2 Parallel, processing 10 files
93.02user 25.15system 0:54.97elapsed 214%CPU (0avgtext+0avgdata 1154904maxresident)k
8inputs+1076824outputs (0major+1335416minor)pagefaults 0swaps

# 2 Parallel, processing 10 files, no spinner
50.57user 4.67system 0:26.88elapsed 205%CPU (0avgtext+0avgdata 1155032maxresident)k
0inputs+1076824outputs (0major+551063minor)pagefaults 0swaps

# 1 Parallel, processing 10 files
99.52user 30.40system 1:34.28elapsed 137%CPU (0avgtext+0avgdata 1155004maxresident)k
0inputs+1076824outputs (0major+1618612minor)pagefaults 0swaps

# 1 Parallel, processing 10 files, no spinner
43.34user 4.16system 0:44.94elapsed 105%CPU (0avgtext+0avgdata 1154928maxresident)k
0inputs+1076824outputs (0major+505954minor)pagefaults 0swaps

# No parallel, processing 10 files
88.26user 16.64system 1:24.37elapsed 124%CPU (0avgtext+0avgdata 1154496maxresident)k
0inputs+1076824outputs (0major+1066120minor)pagefaults 0swaps

# No parallel, processing 10 files, no spinner
43.88user 3.93system 0:45.30elapsed 105%CPU (0avgtext+0avgdata 1154856maxresident)k
0inputs+1076824outputs (0major+492041minor)pagefaults 0swaps

# No parallel, processing 10 files, quiet mode
59.74user 4.80system 1:02.38elapsed 103%CPU (0avgtext+0avgdata 1154544maxresident)k
0inputs+1076824outputs (0major+527644minor)pagefaults 0swaps

# MacBook Pro 2015

                    'c.          julian@Julians-MacBook-Pro
                 ,xNMM.          --------------------------
               .OMMMMo           OS: macOS High Sierra 10.13.2 17C88 x86_64
               OMMM0,            Host: MacBookPro12,1
     .;loddo:' loolloddol;.      Kernel: 17.3.0
   cKMMMMMMMMMMNWMMMMMMMMMM0:    Uptime: 4d 7h 2m
 .KMMMMMMMMMMMMMMMMMMMMMMMWd.    Packages: 197
 XMMMMMMMMMMMMMMMMMMMMMMMX.      Shell: fish 2.7.0
;MMMMMMMMMMMMMMMMMMMMMMMM:       Resolution: 2560x1600
:MMMMMMMMMMMMMMMMMMMMMMMM:       DE: Aqua
.MMMMMMMMMMMMMMMMMMMMMMMMX.      WM: Quartz Compositor
 kMMMMMMMMMMMMMMMMMMMMMMMMWd.    WM Theme: Blue
 .XMMMMMMMMMMMMMMMMMMMMMMMMMMk   Terminal: iTerm2
  .XMMMMMMMMMMMMMMMMMMMMMMMMK.   CPU: Intel i7-5557U (4) @ 3.10GHz
    kMMMMMMMMMMMMMMMMMMMMMMd     GPU: Intel Iris Graphics 6100
     ;KMMMMMMMWXXWMMMMMMMk.      Memory: 3257MiB / 16384MiB
       .cooc,.    .,coo:.


# 4 Parallel, processing 10 files
82.91 real
95.03 user
112.80 sys

# 4 Parallel, processing 10 files, no spinner
42.78 real
72.93 user
8.20 sys

# 2 Parallel, processing 10 files
57.55 real
78.33 user
49.12 sys

# 2 Parallel, processing 10 files, no spinner
36.96 real
59.80 user
6.30 sys

# 1 Parallel, processing 10 files
82.53 real
68.58 user
41.19 sys

# 1 Parallel, processing 10 files, no spinner
67.95 real
56.31 user
6.67 sys

# No parallel, processing 10 files
86.16 real
64.99 user
24.17 sys

# No parallel, processing 10 files, no spinner
66.56 real
56.03 user
6.42 sys

# No parallel, processing 10 files, quiet mode
67.98 real
56.34 user
6.75 sys
```

## Conclusion
From these results, we can see that the spinner would cause the script to slow down by a large margin. The fastest seems to be either 2 parallels with no spinner or no parallel with no spinner. The spinner slowdown could be caused by the fact that it has a small delay time, and loops through `ps`, `awk` and `grep` while doing so. If you wish to turn off the spinner, simply parse the `--no-spinner` flag into the command.