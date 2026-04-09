# Use a lightweight Node.js image
FROM node:18-slim

# Set the working directory inside the container
WORKDIR /app

# Install express directly (to keep it simple for now)
RUN npm install express

# Copy your app code into the container
COPY app.js .

# Open the port the app runs on
EXPOSE 3000

# Start the app
CMD ["node", "app.js"]
