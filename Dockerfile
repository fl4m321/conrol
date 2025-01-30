# Use Ubuntu 22.04 as the base image
FROM ubuntu:22.04

# Install necessary packages (including Node.js and dependencies)
RUN apt-get update && \
    apt-get install -y curl unzip nodejs npm && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Install Node.js (latest LTS version)
RUN curl -fsSL https://deb.nodesource.com/setup_18.x | bash - && \
    apt-get install -y nodejs

# Create a new non-root user and the necessary directories
RUN useradd -m admin && mkdir -p /home/admin/panel

# **Fix Permissions as Root Before Switching Users (No sudo needed)**
RUN chown -R admin:admin /home/admin/panel

# Switch to the non-root user
USER admin
WORKDIR /home/admin/panel

# Copy only the backend files (backend folder)
COPY --chown=admin:admin backend /home/admin/panel/backend

# Verify the backend directory has package.json (for debugging)
RUN ls -l /home/admin/panel/backend  # For debugging, verify package.json is copied

# Install backend dependencies (for Node.js)
WORKDIR /home/admin/panel/backend
RUN npm install --unsafe-perm

# Expose the backend API port (you can choose 3000 or another port)
EXPOSE 3000

# Start backend Node.js server (adjust this based on your server.js file)
CMD ["sh", "-c", "cd /home/admin/panel/backend && node server.js"]
