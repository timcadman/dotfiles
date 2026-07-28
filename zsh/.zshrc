
# Named directories (zsh ~name shortcuts)
hash -d mlg=/Users/tcadman/git-repos/ds-molgenis/molgenis-service-armadillo
hash -d dsb=/Users/tcadman/git-repos/ds-core/dsBase
hash -d dsbc=/Users/tcadman/git-repos/ds-core/dsBaseClient
hash -d dsa="/Users/tcadman/Library/CloudStorage/GoogleDrive-timcadman@gmail.com/Mi unidad/Work/funding/in-progress/FEDHAFRICA"

# nvm
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
autoload -U +X bashcompinit && bashcompinit
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

# PATH
export PATH="/Library/Frameworks/Python.framework/Versions/3.9/bin:$PATH"
export PATH="/Library/Frameworks/Python.framework/Versions/3.13/bin:$PATH"
export PATH="$HOME/Library/Python/3.13/bin:$PATH"
export PATH="$HOME/.local/bin:$PATH"

#THIS MUST BE AT THE END OF THE FILE FOR SDKMAN TO WORK!!!
export SDKMAN_DIR="$HOME/.sdkman"
[[ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]] && source "$HOME/.sdkman/bin/sdkman-init.sh"

# pandoc + typst bundled with RStudio
export PATH="/Applications/RStudio.app/Contents/Resources/app/quarto/bin/tools/aarch64:$PATH"
