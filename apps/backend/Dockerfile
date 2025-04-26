FROM node:16-alpine

WORKDIR /usr/src/app

# Copy package files and install dependencies
COPY package*.json ./
# Replace npm ci with npm install
RUN npm install --production

# Copy application code
COPY . .

# Set environment variables
ENV NODE_ENV=production
ENV PORT=8080

# Expose the port the app runs on
EXPOSE 8080

# Run the application
CMD ["node", "app.js"]