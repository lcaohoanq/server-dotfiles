#!/bin/bash

# Version
RP_VERSION='15.1.0'
FZF_VERSION='0.67.0'

# Màu mè tí cho chuyên nghiệp
GREEN='\033[0;32m'
NC='\033[0m' # No Color

echo -e "${GREEN}[*] Bắt đầu thiết lập Server Survival Kit...${NC}"

# 1. Hàm backup và copy file
install_dotfile() {
  local file=$1
  if [ -f ~/$file ]; then
    echo "    - Backup $file cũ sang $file.bak"
    mv ~/$file ~/$file.bak
  fi
  echo "    - Copy $file mới"
  cp $file ~/$file
}

# 2. Cài đặt Configs (Tmux, Vim)
install_dotfile ".tmux.conf"
install_dotfile ".vimrc"

# 3. Reload tmux nếu đang chạy
if pgrep tmux >/dev/null; then
  tmux source-file ~/.tmux.conf
  echo -e "${GREEN}[*] Đã reload cấu hình Tmux${NC}"
fi

# 4. Tải và cài đặt Tools (Ripgrep, FZF) - Binary tĩnh
ARCH=$(uname -m)
OS=$(uname -s)

if [[ "$OS" == "Linux" && "$ARCH" == "x86_64" ]]; then
  echo -e "${GREEN}[*] Đang tải các tools portable (Ripgrep, FZF)...${NC}"

  # --- Ripgrep ---
  if ! command -v rg &>/dev/null; then
    echo "    -> Installing Ripgrep..."
    curl -LO https://github.com/BurntSushi/ripgrep/releases/download/${RP_VERSION}/ripgrep-${RP_VERSION}-x86_64-unknown-linux-musl.tar.gz
    tar -xzf ripgrep-${RP_VERSION}-x86_64-unknown-linux-musl.tar.gz
    sudo mv ripgrep-${RP_VERSION}-x86_64-unknown-linux-musl/rg /usr/local/bin/
    rm -rf ripgrep-${RP_VERSION}*
  else
    echo "    -> Ripgrep đã cài đặt."
  fi

  # --- FZF Binary ---
  if ! command -v fzf &>/dev/null; then
    echo "    -> Installing FZF Binary..."
    curl -LO https://github.com/junegunn/fzf/releases/download/v${FZF_VERSION}/fzf-${FZF_VERSION}-linux_amd64.tar.gz
    tar -xzf fzf-${FZF_VERSION}-linux_amd64.tar.gz
    sudo mv fzf /usr/local/bin/
    rm -f fzf-${FZF_VERSION}-linux_amd64.tar.gz
  else
    echo "    -> FZF Binary đã cài đặt."
  fi

  # --- FZF Integration (NEW: Key Bindings & Ripgrep Config) ---
  echo -e "${GREEN}[*] Đang cấu hình FZF Integration (Ctrl+T)...${NC}"
  
  # Tải script key-bindings về thư mục home
  # https://github.com/junegunn/fzf/tree/master/shell
  curl -sL https://raw.githubusercontent.com/junegunn/fzf/master/shell/key-bindings.zsh -o ~/.fzf-key-bindings.zsh
  # curl -sL https://raw.githubusercontent.com/junegunn/fzf/master/shell/key-bindings.bash -o ~/.fzf-key-bindings.bash

  # Hàm inject config vào shell rc
  configure_shell() {
      local rc_file=$1
      local binding_file=$2
      
      if [ -f "$rc_file" ]; then
          # Kiểm tra xem đã config chưa để tránh trùng lặp
          if ! grep -q "FZF_DEFAULT_COMMAND" "$rc_file"; then
              echo "    -> Thêm cấu hình vào $rc_file"
              cat <<EOT >> "$rc_file"

            # --- FZF & RIPGREP CONFIG ---
            # Sử dụng Ripgrep làm engine tìm kiếm cho FZF (nhanh, bỏ qua .git)
            export FZF_DEFAULT_COMMAND='rg --files --hidden --follow --glob "!.git/*"'
            export FZF_CTRL_T_COMMAND="\$FZF_DEFAULT_COMMAND"
            
            # Load Key Bindings (Ctrl+T, Alt+C)
            [ -f ~/$binding_file ] && source ~/$binding_file
            # ----------------------------
            EOT
          else
              echo "    -> $rc_file đã có cấu hình FZF. Bỏ qua."
          fi
      fi
  }

  # Thử cấu hình cho cả Zsh và Bash (tùy server dùng shell nào)
  configure_shell "$HOME/.zshrc" ".fzf-key-bindings.zsh"
  # configure_shell "$HOME/.bashrc" ".fzf-key-bindings.bash"

else
  echo "(!) Kiến trúc máy không phải x86_64 hoặc không phải Linux. Bỏ qua bước tải Binary."
fi

echo -e "${GREEN}[DONE] Setup hoàn tất! Hãy source ~/.zshrc (hoặc ~/.bashrc) rồi thử bấm Ctrl+T.${NC}"
