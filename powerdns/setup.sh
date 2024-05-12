# !/bin/bash

# region : set variables


# ------end region------

# update.sh create
cat > update.sh <<EOF
#!/bin/bash
sudo apt update
sudo apt upgrade -y
sudo apt autoremove -y
EOF

chmod 700 update.sh
./update.sh
