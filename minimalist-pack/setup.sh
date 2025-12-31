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

# 2. Cài đặt Configs
install_dotfile ".tmux.conf"
install_dotfile ".vimrc"

# 3. Reload tmux nếu đang chạy
if pgrep tmux >/dev/null; then
  tmux source-file ~/.tmux.conf
  echo -e "${GREEN}[*] Đã reload cấu hình Tmux${NC}"
fi

# 4. Tải và cài đặt Tools (Ripgrep, FZF, Btop) - Binary tĩnh
# Chỉ chạy trên Linux x86_64 (hầu hết server). Nếu ARM thì bỏ qua.
ARCH=$(uname -m)
OS=$(uname -s)

if [[ "$OS" == "Linux" && "$ARCH" == "x86_64" ]]; then
  echo -e "${GREEN}[*] Đang tải các tools portable (Ripgrep, FZF)...${NC}"

  # Tạo thư mục bin cá nhân nếu muốn không cần sudo, nhưng ở đây dùng /usr/local/bin cho chuẩn
  # Cần sudo để ghi vào /usr/local/bin

  # --- Ripgrep ---
  # https://github.com/BurntSushi/ripgrep/releases/tag/15.1.0
  if ! command -v rg &>/dev/null; then
    echo "    -> Installing Ripgrep..."
    curl -LO https://github.com/BurntSushi/ripgrep/releases/download/${RP_VERSION}/ripgrep-${RP_VERSION}-x86_64-unknown-linux-musl.tar.gz
    tar -xzf ripgrep-${RP_VERSION}-x86_64-unknown-linux-musl.tar.gz
    sudo mv ripgrep-${RP_VERSION}-x86_64-unknown-linux-musl/rg /usr/local/bin/
    rm -rf ripgrep-${RP_VERSION}*
  else
    echo "    -> Ripgrep đã cài đặt."
  fi

  # --- FZF ---
  # https://github.com/junegunn/fzf/releases/tag/v0.67.0
  if ! command -v fzf &>/dev/null; then
    echo "    -> Installing FZF..."
    curl -LO https://github.com/junegunn/fzf/releases/download/v${FZF_VERSION}/fzf-${FZF_VERSION}-linux_amd64.tar.gz
    tar -xzf fzf-${FZF_VERSION}-linux_amd64.tar.gz
    sudo mv fzf /usr/local/bin/
    rm -f fzf-${FZF_VERSION}-linux_amd64.tar.gz
  else
    echo "    -> FZF đã cài đặt."
  fi

else
  echo "(!) Kiến trúc máy không phải x86_64 hoặc không phải Linux. Bỏ qua bước tải Binary."
fi

echo -e "${GREEN}[DONE] Setup hoàn tất! Hãy gõ 'tmux' để bắt đầu.${NC}"
