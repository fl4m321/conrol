# Use Ubuntu 22.04 as the base image
FROM ubuntu:22.04

# Install necessary packages (including Docker tools for VPS control, Node.js, and dependencies)
RUN apt-get update && \
    apt-get install -y curl unzip qemu-kvm libvirt-daemon-system libvirt-clients bridge-utils \
    nodejs npm git && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Install Node.js (latest LTS version, for frontend and backend)
RUN curl -fsSL https://deb.nodesource.com/setup_18.x | bash - && \
    apt-get install -y nodejs

# Create a new non-root user and the necessary directories
RUN useradd -m admin && mkdir -p /home/admin/panel

# **Fix Permissions as Root Before Switching Users (No sudo needed)**
RUN chown -R admin:admin /home/admin/panel

# Switch to the non-root user
USER admin
WORKDIR /home/admin/panel

# Copy backend and frontend files as root (before switching to admin user)
COPY --chown=admin:admin backend /home/admin/panel/backend
COPY --chown=admin:admin frontend /home/admin/panel/frontend

# Verify that backend directory has package.json (for debugging)
RUN ls -l /home/admin/panel/backend  # For debugging, verify package.json is copied

# Install backend dependencies (for Node.js)
WORKDIR /home/admin/panel/backend
RUN npm install --unsafe-perm

# Install frontend dependencies and build the frontend
WORKDIR /home/admin/panel/frontend
RUN npm install && npm run build

# Expose the web panel port (React frontend and backend API)
EXPOSE 3000

# Install and configure the VPS manager (e.g., KVM, QEMU, Libvirt)
# Create shell scripts for managing the VPS lifecycle (create, start, stop, etc.)

# Shell script for VPS lifecycle management (start, stop, restart, create, reset)
RUN echo "#!/bin/bash\n\
# Create a new VPS\n\
create_vps() {\n\
  VM_NAME=\$1\n\
  echo 'Creating VPS: ' \$VM_NAME\n\
  virt-install --name \$VM_NAME --memory 1024 --vcpus 1 --disk path=/var/lib/libvirt/images/\$VM_NAME.img,bus=virtio,size=10 --cdrom /path/to/iso --os-type linux --os-variant ubuntu20.04\n\
}\n\
\n\
# Start VPS\n\
start_vps() {\n\
  VM_NAME=\$1\n\
  echo 'Starting VPS: ' \$VM_NAME\n\
  virsh start \$VM_NAME\n\
}\n\
\n\
# Stop VPS\n\
stop_vps() {\n\
  VM_NAME=\$1\n\
  echo 'Stopping VPS: ' \$VM_NAME\n\
  virsh shutdown \$VM_NAME\n\
}\n\
\n\
# Restart VPS\n\
restart_vps() {\n\
  VM_NAME=\$1\n\
  echo 'Restarting VPS: ' \$VM_NAME\n\
  virsh reboot \$VM_NAME\n\
}\n\
\n\
# Reset VPS\n\
reset_vps() {\n\
  VM_NAME=\$1\n\
  echo 'Resetting VPS: ' \$VM_NAME\n\
  virsh destroy \$VM_NAME\n\
  virsh undefine \$VM_NAME\n\
}\n\
\n\
# Admin Panel: List all VMs\n\
list_vms() {\n\
  virsh list --all\n\
}\n\
\n\
# Provide menu options\n\
echo 'Select VPS Management Action: Create, Start, Stop, Restart, Reset, List'\n\
read ACTION\n\
\n\
case \$ACTION in\n\
  'create')\n\
    echo 'Enter VPS name to create:'\n\
    read VM_NAME\n\
    create_vps \$VM_NAME\n\
    ;;\n\
  'start')\n\
    echo 'Enter VPS name to start:'\n\
    read VM_NAME\n\
    start_vps \$VM_NAME\n\
    ;;\n\
  'stop')\n\
    echo 'Enter VPS name to stop:'\n\
    read VM_NAME\n\
    stop_vps \$VM_NAME\n\
    ;;\n\
  'restart')\n\
    echo 'Enter VPS name to restart:'\n\
    read VM_NAME\n\
    restart_vps \$VM_NAME\n\
    ;;\n\
  'reset')\n\
    echo 'Enter VPS name to reset:'\n\
    read VM_NAME\n\
    reset_vps \$VM_NAME\n\
    ;;\n\
  'list')\n\
    list_vms\n\
    ;;\n\
  *)\n\
    echo 'Invalid action selected.'\n\
    ;;\n\
esac\n" > /home/admin/panel/vps_manager.sh

# Make the script executable
RUN chmod +x /home/admin/panel/vps_manager.sh

# Start both frontend (React) and backend (Node.js) APIs
CMD ["sh", "-c", "cd /home/admin/panel/backend && node server.js & cd /home/admin/panel/frontend && npm start && wait"]
