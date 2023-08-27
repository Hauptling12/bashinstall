#!/bin/bash
os_name=$(cat /etc/os-release|sed -n 1p | grep -oP '(?<=").*(?=")' | awk '{print $1}')
if [[ $(which dialog) != "/usr/bin/dialog" ]];then
     echo "Dialog Not Installed"
     exit 1
fi

set -a
SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
set +a
wget -q --spider http://aur.archlinux.org

if [ $? -eq 0 ]; then
    echo "Online"
else
    echo "Can Not Connect To The Internet Error"
    exit 1
fi
choice=$(dialog \
                --input-fd  2 \
                --output-fd 1 \
                --title "Bash Linux Installer" \
                --menu "Choose What Type Of Install" \
                15 40 4 \
                1 "desktop" \
                2 "server" \
                )


case $choice in
        1)
            pkg_choice=$(dialog --input-fd  2 --output-fd 1 --checklist "Choose Packages To Install" 15 40 3 1 'base pkgss' 'on' 2 'dev pkgs' 'on' 3 'graphics and audio pkgs' 'on' 4 'gaming pkgs' 'off')
            laptop_choice=$(dialog --title "Verification" --yesno "Are You Installing On A Laptop" 7 60 )
            mkdir "/home/$USERNAME/.cache" || exit 1
            touch "/home/$USERNAME/.cache/.zshhistory" || exit 1
            curl -L https://nixos.org/nix/install | sh
            mkdir "$HOME/build" || exit 1
            if [[ $os_name == "Debian" ]]; then
                deb_sid=$(cat /etc/os-release|sed -n 1p | grep -oP '(?<=").*(?=")' | sed 's/\// /g' |awk '{print $NF}')
                sudo apt update || exit 1
                sudo apt upgrade -y || exit 1
                sudo apt install nala || exit 1
                if [[ $deb_sid != "sid" ]];then
                     if dialog --title "Switch to debain sid"  --yesno "You Are Running Debain Stable The Install Script Will Not Work Switch To Sid?" 0 0;then
                         sudo cp /etc/apt/sources.list sources.list.backup || exit 1
                         sudo sed -i 's/bookworm/unstable/g' /etc/apt/sources.list || exit 1
                         sudo apt update || exit 1
                         sudo apt upgrade -y || exit 1
                     else
                         echo -ne "
                         ------------------------------------------------------------------------
                                    Install Will Not Work in Debain Stable
                         ------------------------------------------------------------------------
                         "
                         exit 1
                     fi
                fi
                echo $pkg_choice
                #     if [[]]
                for choices in $pkg_choice
                do
                    case $choices in
                        1)
                            echo -ne "
                            ------------------------------------------------------------------------
                                        Installing Base Packages
                            ------------------------------------------------------------------------
                            "
                            sudo apt install < $SCRIPT_DIR/pkg/pkg-base-apt.txt
                            ;;
                        2)
                            echo -ne "
                            ------------------------------------------------------------------------
                                        Installing Development Packages
                            ------------------------------------------------------------------------
                            "
                            sudo apt install < $SCRIPT_DIR/pkg/pkg-dev-apt.txt
                            ./$HOME/.nix-profile/bin/nix-env -iA nixpkgs.onefetch nixpkgs.bandwhich nixpkgs.haskell-language-server nixpkgs.nodePackages.bash-language-server
                            ;;
                        3)
                            echo -ne "
                            ------------------------------------------------------------------------
                                        Installing Graphics And Audio Packages
                            ------------------------------------------------------------------------
                            "
                            sudo apt install < $SCRIPT_DIR/pkg/pkg-graphics-apt.txt
                            ! [ -d /etc/apt/keyrings ] && sudo mkdir -p /etc/apt/keyrings && sudo chmod 755 /etc/apt/keyrings

                            wget -O- https://download.opensuse.org/repositories/home:/bgstack15:/aftermozilla/Debian_Unstable/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/home_bgstack15_aftermozilla.gpg

                            sudo tee /etc/apt/sources.list.d/home_bgstack15_aftermozilla.sources << EOF > /dev/null
Types: deb
URIs: https://download.opensuse.org/repositories/home:/bgstack15:/aftermozilla/Debian_Unstable/
Suites: /
Signed-By: /etc/apt/keyrings/home_bgstack15_aftermozilla.gpg
EOF

                            sudo apt update

                            sudo apt install librewolf -y
                            echo -ne "
                            ------------------------------------------------------------------------
                                        Installing Suckless Progams
                            ------------------------------------------------------------------------
                            "
                            cd "$HOME/build" ||exit 1
                            git clone https://github.com/Hauptling12/st_build
                            cd st_build || exit 1
                            sudo cp st st-copyout st-urlhandler /usr/local/bin
                            cd  "$HOME/build" || exit 1
                            git clone https://github.com/Hauptling12/dmenu_build
                            cd dmenu_build || exit 1
                            sudo make install || exit 1
                            cd "$HOME/build" || exit
                            git clone https://git.suckless.org/slock
                            cd slock || exit
                            touch config.h
                            cat config.def.h | sed -e "s/nobody/$USERNAME/g" -e "s/nogroup/$USERNAME/g" > config.h
                            sudo make install
                            cd "$HOME/build"
                            wget https://github.com/B00merang-Project/Windows-10-Dark/archive/refs/tags/3.2.1-dark.tar.gz
                            tar -vxf 3.2.1-dark.tar.gz
                            sudo cp 3.2.1-dark /usr/share/themes/
                            git clone https://github.com/HenriqueLopes42/themeGrub.CyberEXS CyberEXS
                            git clone https://github.com/yeyushengfan258/Win11-icon-theme
                            sudo cp -irv Win11-icon-theme/src/ /usr/share/icons/Win11-icon-theme
                            ;;
                        4)
                            echo -ne "
                            ------------------------------------------------------------------------
                                        Installing Gaming Packages
                            ------------------------------------------------------------------------
                            "
                            sudo dpkg --add-architecture i386
                            echo "deb https://dl.winehq.org/wine-builds/debian/ sid main"|sudo tee -a /etc/apt/sources.list
                            sudo nala update
                            sudo nala install winehq-staging winetricks lutris mangohud gamescope gamemode
                            mkdir "/home/USERNAME/.local/share/lutris/runners/wine/"
                            wget https://github.com/GloriousEggroll/wine-ge-custom/releases/download/GE-Proton8-14/wine-lutris-GE-Proton8-14-x86_64.tar.xz
                            mv wine-lutris-GE-Proton8-14-x86_64.tar.xz "/home/USERNAME/.local/share/lutris/runners/wine/"
                            ;;
                    esac
                done
                echo "debain"
            elif [[ $os_name == "Fedora" ]]; then
                for choices in $pkg_choice
                do
                    case $choices in
                        1)
                            echo -ne "
                            ------------------------------------------------------------------------
                                        Installing Base Packages
                            ------------------------------------------------------------------------
                            "
                            sudo dnf install < $SCRIPT_DIR/pkg/pkg-base-dnf.txt || exit 1
                            ;;
                        2)
                            echo -ne "
                            ------------------------------------------------------------------------
                                        Installing Development Packages
                            ------------------------------------------------------------------------
                            "
                            sudo dnf install < $SCRIPT_DIR/pkg/pkg-dev-dnf.txt || exit 1
                            ./$HOME/.nix-profile/bin/nix-env -iA nixpkgs.sc-im nixpkgs.onefetch nixpkgs.bandwhich nixpkgs.haskell-language-server
                            ;;
                        3)
                            echo -ne "
                            ------------------------------------------------------------------------
                                        Installing Graphics And Audio Packages
                            ------------------------------------------------------------------------
                            "
                            sudo dnf install < $SCRIPT_DIR/pkg/pkg-graphics-dnf.txt || exit 1
                            sudo dnf config-manager --add-repo https://rpm.librewolf.net/librewolf-repo.repo
                            sudo dnf install librewolf
                            echo -ne "
                            ------------------------------------------------------------------------
                                        Installing Suckless Progams
                            ------------------------------------------------------------------------
                            "
                            cd "$HOME/build" ||exit 1
                            git clone https://github.com/Hauptling12/st_build
                            cd st_build || exit 1
                            sudo cp st st-copyout st-urlhandler /usr/local/bin
                            cd  "$HOME/build" || exit 1
                            git clone https://github.com/Hauptling12/dmenu_build
                            cd dmenu_build || exit 1
                            sudo make install || exit 1
                            cd "$HOME/build" || exit
                            git clone https://git.suckless.org/slock
                            cd slock || exit
                            touch config.h
                            cat config.def.h | sed -e "s/nobody/$USERNAME/g" -e "s/nogroup/$USERNAME/g" > config.h
                            sudo make install
                            cd "$HOME/build"
                            wget https://github.com/B00merang-Project/Windows-10-Dark/archive/refs/tags/3.2.1-dark.tar.gz
                            tar -vxf 3.2.1-dark.tar.gz
                            sudo cp 3.2.1-dark /usr/share/themes/
                            git clone https://github.com/HenriqueLopes42/themeGrub.CyberEXS CyberEXS
                            git clone https://github.com/yeyushengfan258/Win11-icon-theme
                            sudo cp -irv Win11-icon-theme/src/ /usr/share/icons/Win11-icon-theme
                            ;;
                        4)
                            echo -ne "
                            ------------------------------------------------------------------------
                                        Installing Gaming Packages
                            ------------------------------------------------------------------------
                            "
                            sudo dnf install > $SCRIPT_DIR/pkg/pkg-gaming-dnf.txt ||exit 1
                            mkdir "/home/USERNAME/.local/share/lutris/runners/wine/"
                            wget https://github.com/GloriousEggroll/wine-ge-custom/releases/download/GE-Proton8-14/wine-lutris-GE-Proton8-14-x86_64.tar.xz
                            mv wine-lutris-GE-Proton8-14-x86_64.tar.xz "/home/USERNAME/.local/share/lutris/runners/wine/"
                            ;;
                    esac
                done
            elif [[ $os_name == "Arch" ]]; then
                sudo sed -i 's/^#ParallelDownloads/ParallelDownloads/' /etc/pacman.conf
                sudo pacman -S --noconfirm archlinux-keyring | exit 1 #update keyrings to latest to prevent packages failing to install
                sudo pacman -S --noconfirm --needed pacman-contrib terminus-font git || exit 1
                setfont ter-v22b
                nc=$(grep -c ^processor /proc/cpuinfo)
                echo -ne "
                -------------------------------------------------------------------------
                                You have " $nc" cores. And
			                changing the makeflags for "$nc" cores. Aswell as
				            changing the compression settings.
                -------------------------------------------------------------------------
"
                TOTAL_MEM=$(cat /proc/meminfo | grep -i 'memtotal' | grep -o '[[:digit:]]*')
                if [[  $TOTAL_MEM -gt 8000000 ]]; then
                sudo sed -i "s/#MAKEFLAGS=\"-j2\"/MAKEFLAGS=\"-j$nc\"/g" /etc/makepkg.conf
                sudo sed -i 's/^#Color/Color\nILoveCandy/'
                sudo sed -i "s/COMPRESSXZ=(xz -c -z -)/COMPRESSXZ=(xz -c -T $nc -z -)/g" /etc/makepkg.conf
                fi
                cd "$HOME/build"||exit 1
                git clone https://aur.archlinux.org/paru.git
                cd paru || exit 1
                makepkg -si ||exit 1
                for choices in $pkg_choice
                do
                    case $choices in
                        1)
                            echo -ne "
                            ------------------------------------------------------------------------
                                        Installing Base Packages
                            ------------------------------------------------------------------------
                            "
                            sudo pacman -S --noconfirm --needed < "$SCRIPT_DIR/pkg/pkg-base-pacman.txt" || exit 1
                            ;;
                        2)
                            echo -ne "
                            ------------------------------------------------------------------------
                                        Installing Development Packages
                            ------------------------------------------------------------------------
                            "
                            ./$HOME/.nix-profile/bin/nix-env -iA nixpkgs.drawio
                            sudo pacman -S --noconfirm --needed < "$SCRIPT_DIR/pkg/pkg-dev-pacman.txt" || exit 1
                            paru -S --nodiffmenu -S < "$SCRIPT_DIR/pkg/pkg-dev-aur.txt" || exit 1
                            ;;
                        3)
                            echo -ne "
                            ------------------------------------------------------------------------
                                        Installing Graphics And Audio Packages
                            ------------------------------------------------------------------------
                            "
                            sudo pacman -S --noconfirm --needed < "$SCRIPT_DIR/pkg/pkg-graphics-pacman.txt" || exit 1
                            paru -S --nodiffmenu < "$SCRIPT_DIR/pkg/pkg-graphics-aur.txt" || exit 1
                            echo -ne "
                            -------------------------------------------------------------------------
                                        Installing Graphics Drivers
                            -------------------------------------------------------------------------
                            "
                            # Graphics Drivers find and install
                            gpu_type=$(lspci)
                            if grep -E "NVIDIA|GeForce" <<< ${gpu_type}; then
                                sudo pacman -S --noconfirm --needed nvidia || exit 1
	                            nvidia-xconfig
                            elif lspci | grep 'VGA' | grep -E "Radeon|AMD"; then
                                sudo pacman -S --noconfirm --needed xf86-video-amdgpu || exit 1
                            elif grep -E "Integrated Graphics Controller" <<< ${gpu_type}; then
                                sudo pacman -S --noconfirm --needed libva-intel-driver libvdpau-va-gl lib32-vulkan-intel vulkan-intel libva-intel-driver libva-utils lib32-mesa || exit 1
                            elif grep -E "Intel Corporation UHD" <<< ${gpu_type}; then
                                sudo pacman -S --needed --noconfirm libva-intel-driver libvdpau-va-gl lib32-vulkan-intel vulkan-intel libva-intel-driver libva-utils lib32-mesa || exit 1
                            fi
                            echo -ne "
                            ------------------------------------------------------------------------
                                        Installing Suckless Progams
                            ------------------------------------------------------------------------
                            "
                            cd "$HOME/build" ||exit 1
                            git clone https://github.com/Hauptling12/st_build
                            cd st_build || exit 1
                            sudo cp st st-copyout st-urlhandler /usr/local/bin
                            cd  "$HOME/build" || exit 1
                            git clone https://github.com/Hauptling12/dmenu_build
                            cd dmenu_build || exit 1
                            sudo make install || exit 1
                            cd "$HOME/build" || exit
                            git clone https://git.suckless.org/slock
                            cd slock || exit
                            touch config.h
                            cat config.def.h | sed -e "s/nobody/$USERNAME/g" -e "s/nogroup/$USERNAME/g" > config.h
                            sudo make install
                            cd "$HOME/build"
                            wget https://github.com/B00merang-Project/Windows-10-Dark/archive/refs/tags/3.2.1-dark.tar.gz
                            tar -vxf 3.2.1-dark.tar.gz
                            sudo cp 3.2.1-dark /usr/share/themes/
                            git clone https://github.com/HenriqueLopes42/themeGrub.CyberEXS CyberEXS
                            git clone https://github.com/yeyushengfan258/Win11-icon-theme
                            sudo cp -irv Win11-icon-theme/src/ /usr/share/icons/Win11-icon-theme

                            ;;
                        4)
                            echo -ne "
                            ------------------------------------------------------------------------
                                        Installing Gaming Packages
                            ------------------------------------------------------------------------
                            "
                            #Enable multilib
                            sudo sed -i "/\[multilib\]/,/Include/"'s/^#//' /etc/pacman.conf || exit 1
                            sudo pacman -Sy --noconfirm --needed || exit 1
                            sudo pacman -S --noconfirm --needed < $SCRIPT_DIR/pkg/pkg-gaming-pacman.txt || exit 1
                            mkdir "/home/USERNAME/.local/share/lutris/runners/wine/"
                            wget https://github.com/GloriousEggroll/wine-ge-custom/releases/download/GE-Proton8-14/wine-lutris-GE-Proton8-14-x86_64.tar.xz
                            mv wine-lutris-GE-Proton8-14-x86_64.tar.xz "/home/USERNAME/.local/share/lutris/runners/wine/"

                            ;;
                    esac
                done
                git clone https://aur.archlinux.org/yay.git && cd yay && makepkg -si
            fi
            echo "blacklist pcspkr" | sudo tee -a /etc/modprobe.d/blacklist.conf
            chsh -s /usr/bin/zsh
            sudo ln -sfT dash /usr/bin/sh
            chezmoi init https://github.com/hauptling12/dotfiles
            chezmoi cd
            ## Check what changes that chezmoi will make to your home directory by running:

            ## then to copy dotfiles run
            chezmoi apply -v
            sudo ufw limit 22/tcp
            sudo ufw allow 80/tcp
            sudo ufw allow 443/tcp
            sudo ufw default deny incoming
            sudo ufw default allow outgoing
            sudo ufw enable
            ;;
        2)
            echo "You chose Option 2"
            ;;
esac
