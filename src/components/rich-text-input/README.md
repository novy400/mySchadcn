# Rich Text Input Component

## Overview

This directory contains rich text input components for the application. There are two versions:

1. **RichTextInput** - The full-featured version with all TipTap extensions
2. **SimpleRichTextInput** - A simplified version with fewer dependencies

## When to use which version

- Use **SimpleRichTextInput** for basic rich text needs (bold, italic, lists, etc.)
- Use **RichTextInput** when you need advanced features like code blocks, images, etc.

## Architecture

The component is built on top of TipTap, with additional UI components for the toolbar and formatting options.

## Dependencies

- @tiptap/react
- @tiptap/starter-kit
- And various extensions for advanced features

## Testing

Tests are located in:
- `rich-text-input.test.tsx` - Basic tests for RichTextInput
- `simple-rich-text-input.test.tsx` - Basic tests for SimpleRichTextInput

Note: Integration tests require a full browser environment and are currently limited.