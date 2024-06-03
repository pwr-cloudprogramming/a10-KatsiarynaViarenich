# Use an official Node.js runtime as a parent image
FROM node:22

# Set the working directory to /app
WORKDIR /app

# Copy the package.json and package-lock.json files to the working directory
COPY . .

# Install the dependencies
RUN npm i

EXPOSE 8082

# Command to run the development server
CMD ["npm", "run", "dev"]

