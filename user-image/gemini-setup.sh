#!/bin/bash
# Gemini API setup script for JupyterHub users

echo "Setting up Gemini API environment..."

# Create .env file if it doesn't exist
if [ ! -f "$HOME/.env" ]; then
    echo "Creating .env file..."
    cat > "$HOME/.env" << EOF
# Gemini API Configuration
GEMINI_API_KEY=your-gemini-api-key-here

# Other API Keys (optional)
OPENAI_API_KEY=your-openai-api-key-here
EOF
    echo "✓ Created .env file at $HOME/.env"
    echo "  Please update it with your actual API keys"
fi

# Create sample notebook for Gemini API usage
if [ ! -f "$HOME/work/gemini-quickstart.ipynb" ]; then
    echo "Creating Gemini quickstart notebook..."
    cat > "$HOME/work/gemini-quickstart.ipynb" << 'EOF'
{
 "cells": [
  {
   "cell_type": "markdown",
   "metadata": {},
   "source": [
    "# Gemini API Quickstart\n",
    "\n",
    "This notebook demonstrates how to use the Gemini API in Python."
   ]
  },
  {
   "cell_type": "code",
   "execution_count": null,
   "metadata": {},
   "outputs": [],
   "source": [
    "# Load environment variables\n",
    "from dotenv import load_dotenv\n",
    "import os\n",
    "\n",
    "load_dotenv()\n",
    "\n",
    "# Get API key from environment\n",
    "GEMINI_API_KEY = os.getenv('GEMINI_API_KEY')\n",
    "\n",
    "if not GEMINI_API_KEY:\n",
    "    print(\"Please set your GEMINI_API_KEY in the .env file\")\n",
    "else:\n",
    "    print(\"API key loaded successfully\")"
   ]
  },
  {
   "cell_type": "code",
   "execution_count": null,
   "metadata": {},
   "outputs": [],
   "source": [
    "# Import and configure Gemini\n",
    "import google.generativeai as genai\n",
    "\n",
    "genai.configure(api_key=GEMINI_API_KEY)\n",
    "\n",
    "# List available models\n",
    "for m in genai.list_models():\n",
    "    if 'generateContent' in m.supported_generation_methods:\n",
    "        print(m.name)"
   ]
  },
  {
   "cell_type": "code",
   "execution_count": null,
   "metadata": {},
   "outputs": [],
   "source": [
    "# Create a model instance\n",
    "model = genai.GenerativeModel('gemini-pro')\n",
    "\n",
    "# Generate content\n",
    "response = model.generate_content(\"Explain how to use Gemini API in Python\")\n",
    "print(response.text)"
   ]
  }
 ],
 "metadata": {
  "kernelspec": {
   "display_name": "Python 3",
   "language": "python",
   "name": "python3"
  },
  "language_info": {
   "name": "python",
   "version": "3.10.0"
  }
 },
 "nbformat": 4,
 "nbformat_minor": 4
}
EOF
    echo "✓ Created Gemini quickstart notebook"
fi

echo "✓ Gemini setup complete!"
echo ""
echo "Next steps:"
echo "1. Edit ~/.env and add your GEMINI_API_KEY"
echo "2. Open the gemini-quickstart.ipynb notebook to get started"
echo "3. Visit https://makersuite.google.com/app/apikey to get your API key"