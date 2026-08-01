{ pkgs, ... }:

let

  ROOT = ./../..;
  cfg = import (ROOT + "/software.nix") { inherit pkgs; };

in

{
  
  programs.zsh = {
    enableCompletion = true;
    autosuggestions.enable = true;
    syntaxHighlighting.enable = true;

    shellAliases = {
      ssh-identity-git = "sh ~/.config/zsh/scripts/ssh-identity-git.sh";

      # Added for the local Ryzen power-limit helper.
      # The script escalates with sudo by itself when root access is required.
      ryzenadj-mode = "~/.config/zsh/scripts/ryzenadj-mode.sh";
    };

    # Added completion for the local ryzenadj-mode helper:
    # modes, common options, manual ryzenadj options, and relative parameters.
    interactiveShellInit = ''
      _ryzenadj_mode() {
        local -a modes common_opts ryzen_opts relative_params boost_modes
        modes=(
          '--status:show watch-friendly targets, actual values, CPU controls, and metrics'
          '--help:show complete command and parameter help'
          'status:show current ryzenadj-mode state and ryzenadj info'
          'stop:stop enforcer and restore saved state'
          # Keep restore discoverable as the explicit equivalent of stop.
          'restore:stop enforcer and restore saved state'
          # Expose the script's base-profile command in shell completion.
          'defaults:stop enforcer and apply configured base limits'
          'manual:enforce explicitly provided ryzenadj options'
          'relative:scale defaults by one selected parameter'
          'help:show help'
        )
        common_opts=(
          '--interval[enforcement period in seconds]:seconds:'
          # Group percentage controls added for the expanded relative/manual profiles.
          '--limit[scale every supplied/generated *-limit parameter]:percent:'
          '--temp[scale every supplied/generated *-temp parameter]:percent:'
          '--current[scale every supplied/generated *-current parameter]:percent:'
          '--boost[force CPU boost state]:boost:(on off)'
          '--min-freq[set CPU minimum frequency in kHz]:kHz:'
          '--max-freq[set CPU maximum frequency in kHz]:kHz:'
          '--freq[set fixed CPU frequency in kHz]:kHz:'
          '--cores[keep N logical CPUs online]:cores:'
          '--once[apply once without background enforcer]'
          '--help[show help]'
        )
        boost_modes=(on off)
        relative_params=(
          'stapm-limit'
          'fast-limit'
          'slow-limit'
          'apu-slow-limit'
          'tctl-temp'
          'vrm-current'
          'vrmsoc-current'
          'vrmmax-current'
          'vrmsocmax-current'
        )
        ryzen_opts=(
          '--stapm-limit[Sustained Power Limit, mW]:mW:'
          '--fast-limit[Fast PPT power limit, mW]:mW:'
          '--slow-limit[Slow PPT power limit, mW]:mW:'
          '--slow-time[Slow PPT constant time, seconds]:seconds:'
          '--stapm-time[STAPM constant time, seconds]:seconds:'
          '--tctl-temp[Tctl temperature limit, C]:C:'
          '--vrm-current[VRM current limit VDD, mA]:mA:'
          '--vrmsoc-current[VRM current limit SoC, mA]:mA:'
          '--vrmgfx-current[VRM current limit GFX, mA]:mA:'
          '--vrmcvip-current[VRM current limit CVIP, mA]:mA:'
          '--vrmmax-current[VRM max current limit VDD, mA]:mA:'
          '--vrmsocmax-current[VRM max current limit SoC, mA]:mA:'
          # These three options use underscores in ryzenadj v0.19.0.
          '--vrmgfxmax_current[VRM max current limit GFX, mA]:mA:'
          '--psi0-current[PSI0 VDD current limit, mA]:mA:'
          '--psi3cpu_current[PSI3 CPU current limit, mA]:mA:'
          '--psi0soc-current[PSI0 SoC current limit, mA]:mA:'
          '--psi3gfx_current[PSI3 GFX current limit, mA]:mA:'
          '--max-socclk-frequency[maximum SoC clock, MHz]:MHz:'
          '--min-socclk-frequency[minimum SoC clock, MHz]:MHz:'
          '--max-fclk-frequency[maximum FCLK, MHz]:MHz:'
          '--min-fclk-frequency[minimum FCLK, MHz]:MHz:'
          '--max-vcn[maximum VCN, MHz]:MHz:'
          '--min-vcn[minimum VCN, MHz]:MHz:'
          '--max-lclk[maximum LCLK, MHz]:MHz:'
          '--min-lclk[minimum LCLK, MHz]:MHz:'
          '--max-gfxclk[maximum GFX clock, MHz]:MHz:'
          '--min-gfxclk[minimum GFX clock, MHz]:MHz:'
          '--prochot-deassertion-ramp[PROCHOT deassertion ramp]:value:'
          '--apu-skin-temp[APU skin temperature limit, C]:C:'
          '--dgpu-skin-temp[dGPU skin temperature limit, C]:C:'
          '--apu-slow-limit[APU slow PPT limit, mW]:mW:'
          '--skin-temp-limit[skin temperature power limit, mW]:mW:'
          '--gfx-clk[forced GFX clock, MHz]:MHz:'
          '--oc-clk[forced core clock, MHz]:MHz:'
          '--oc-volt[forced core VID]:VID:'
          '--set-coall[all-core curve optimizer]:value:'
          '--set-coper[per-core curve optimizer]:value:'
          '--set-cogfx[iGPU curve optimizer]:value:'
          '--enable-oc[enable OC]'
          '--disable-oc[disable OC]'
          '--power-saving[apply hidden power-saving options]'
          '--max-performance[apply hidden max-performance options]'
        )

        if (( CURRENT == 2 )); then
          _describe 'mode' modes
          return
        fi

        case "''${words[2]}" in
          manual)
            _arguments -s -S $common_opts $ryzen_opts '*::arg:_default'
            ;;
          relative)
            if (( CURRENT <= 3 )); then
              _arguments -s -S $common_opts '1:parameter:->relative_parameter' '2:value:'
              if [[ $state == relative_parameter ]]; then
                _describe 'relative parameter' relative_params
              fi
            else
              _arguments -s -S $common_opts $ryzen_opts '*::arg:_default'
            fi
            ;;
          *)
            _arguments '1:mode:->mode'
            if [[ $state == mode ]]; then
              _describe 'mode' modes
            fi
            ;;
        esac
      }
      compdef _ryzenadj_mode ryzenadj-mode ryzenadj-mode.sh
    '';
  };

  home-manager.users.${cfg.user.name} = { config, ... }: {
    xdg.configFile."zsh/scripts/ssh-identity-git.sh" = {
      source = config.lib.file.mkOutOfStoreSymlink "${ROOT}/.config/zsh/scripts/ssh-identity-git.sh";
      force = true;
    };

    # Added as an out-of-store managed script so edits in this repo are used
    # directly by ~/.config/zsh/scripts/ryzenadj-mode.sh after activation.
    # Keep this as a plain absolute string path; using ${ROOT} here coerces
    # the script into /nix/store and leaves shells running an older copy.
    xdg.configFile."zsh/scripts/ryzenadj-mode.sh" = {
      source = config.lib.file.mkOutOfStoreSymlink "/home/ami/.config/nixos/.config/zsh/scripts/ryzenadj-mode.sh";
      force = true;
    };
  };

}
