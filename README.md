
Japanese version: [README.ja.md](README.ja.md)

# Unified Flash Messages Example

This repository is a demo application that demonstrates the concept of handling both server-side flash messages and client-side messages with the same template and display logic. The example is implemented with Rails and Hotwire.

The goal is to improve UI consistency and maintainability by displaying messages from different sources in a unified appearance and structure.


## Background and Issues

With the standard usage of Rails flash, messages are limited to server-side redirects or rendering results. On the other hand, temporary client-side messages (used like flash) are often implemented with separate UIs (alert/toast/modal, etc.), which always raises concerns such as:

- Maintaining consistency in wording and appearance due to separate templates
- Adjusting display timing and position for each message source, and logic to avoid duplicate displays

To solve these concerns, this app attempts a two-step process: generating messages = embedding them in the page, and rendering = formatting and displaying the embedded messages.

The core of this implementation is the mechanism of "collecting messages by embedding them in the page before displaying, and rendering them at the appropriate timing." This does not depend on Rails, Hotwire, or the JavaScript implementation style, so it can be implemented in other frameworks or pure JavaScript as well.


## Processing Flow Overview

The main points are as follows:

* Flash messages generated on the server are embedded in a hidden DOM (called "storage").
* When displaying messages from the client side, the same process is followed: messages are first embedded in the storage.
* When a page change occurs, messages embedded in the storage are retrieved, formatted with templates, and rendered in the display area.

Below, the implementation details in this app are explained with concrete examples.

The main implementation is in `app/javascript/flash_messages.js`. The JavaScript functions described below are exported as ES modules and should be imported for use.

### Initialization

On page load, call `initializeFlashMessageSystem()` to set up event listeners for page changes.

### Embedding Messages (Server-side)

When you set `redirect_to ..., notice: "..."` or `flash.now[:alert] = "..."` in the controller, generate a list with the following structure in the view (this is detected by `flash_messages.js`):

```html
<div data-flash-storage style="display: none;">
  <ul>
    <li data-type="alert">Alert message</li>
  </ul>
</div>
```

### Embedding Messages (Client-side)

The process is the same as on the server side. To add the same HTML structure, call `appendMessageToStorage()`:

```javascript
appendMessageToStorage('Info message', 'info');
```

### Aggregation and Rendering

When a response from the server is rendered, an event handler for page changes fires and executes `renderFlashMessages()`, which performs the following three steps:

1. All `<li>` messages in `[data-flash-storage]` are collected.
2. For each message `type`, the corresponding `<template>` is cloned and the display HTML is formatted.
3. The results are inserted into `[data-flash-message-container]`.

In other words, when server-side flash embedding occurs on the page, these steps run automatically.

If you want to render messages at any timing on the client side, just call `renderFlashMessages()` directly:

```javascript
renderFlashMessages();
```

Once collected, messages are removed from the DOM to prevent duplicate display.


## How to Use flash_messages.js

The core of this demo is implemented in `app/javascript/flash_messages.js`. To use this file, set it up as follows.

### JavaScript Setup

This application uses Importmap, so add the mapping for `flash_messages.js` in `config/importmap.rb`:

```ruby
pin "flash_messages", to: "flash_messages.js"
```

Call the initialization function once on page load:

```javascript
import { initializeFlashMessageSystem } from "flash_messages"

if (document.readyState === "loading") {
  document.addEventListener("DOMContentLoaded", initializeFlashMessageSystem);
} else {
  initializeFlashMessageSystem();
}
```

### Page Setup

Set up `<template>` tags (one for each type) anywhere on the page:

```html
<template id="flash-message-template-alert">
  <div class="bg-red-100" role="alert">
    <span class="flash-message-text"></span>
  </div>
</template>
<template id="flash-message-template-info">
  <div class="bg-blue-100" role="alert">
    <span class="flash-message-text"></span>
  </div>
</template>
```

Place the message display area wherever you like:

```html
<div data-flash-message-container="true">
</div>
```

When `renderFlashMessages()` is executed, the embedded messages are inserted into the display area as follows. The source of the messages is not distinguished; if multiple messages exist on the page, all will be displayed:

```html
<div data-flash-message-container="true">
  <div class="bg-red-100" role="alert">
    <span class="flash-message-text">Alert message</span>
  </div>
  <div class="bg-blue-100" role="alert">
    <span class="flash-message-text">Info message</span>
  </div>
</div>
```

Once collected, messages are removed from the DOM to prevent duplicate display.


### Tag Helpers

Since tag generation for setup is patterned, main helper functions are provided in `ApplicationHelper`:

| Helper Function            | Description                                                                 |
|----------------------------|-----------------------------------------------------------------------------|
| `flash_storage`            | Generates a hidden DOM area to embed server-generated flash messages         |
| `flash_templates`          | Generates HTML templates (`<template>` tags) for each message type          |
| `flash_container`          | Generates a container (display area) for messages                           |
| `flash_global_storage`     | Generates a global storage for Turbo Stream. Not needed if you do not use Turbo Stream. |
| `flash_general_error_messages` | Generates a list of general messages for HTTP status and network errors. Used for the extension features described below. |


### Public API

The following functions are exported from `flash_messages.js`:

| Function                                 | Description                                                                 |
|------------------------------------------|-----------------------------------------------------------------------------|
| `initializeFlashMessageSystem()`         | Registers events and initializes on page load                               |
| `appendMessageToStorage(message, type='alert')` | Stores any message in the storage (for later rendering)              |
| `renderFlashMessages()`                  | Aggregates messages from all storage and renders them using templates by type |
| `clearFlashMessages(message?)`           | Clears displayed messages. If `message` is omitted, all messages are cleared |


## Environment Setup

To try this Rails application, set up your environment as follows.

### Using Docker Compose

A `compose.yml` is provided. Please check its contents and build:

```bash
$ docker compose up --build
```

Once the container is up, run the "Initial Setup" described below from inside the container.

Note: The Rails server does not start automatically when the container launches. Start the server and run all Rails commands from inside the container. To make the server accessible from outside the container, bind to `0.0.0.0`:

```bash
$ docker compose exec -e BINDING=0.0.0.0 web bin/rails s
```

The container started by this compose file uses a bind mount to mount the current directory on the host to the container. Changes on the host are immediately reflected in Rails inside the container.

### Without Docker

This is a simple Rails app, so nothing special is required. The database uses SQLite3, so just initialize it and start the server.

### Initial Setup

Run `bundle install` and set up the database:

```bash
$ docker compose exec web bundle install
$ docker compose exec web bin/rails db:prepare
```

Or:

```bash
$ docker compose exec web bin/setup --skip-server
```

### Tailwind CSS

Since Tailwind is used for CSS, you need to build it when you first set up or after changing CSS:

```bash
$ docker compose exec web bin/rails tailwindcss:build
```

During development, it is convenient to run the process that automatically detects changes and rebuilds:

```bash
$ docker compose exec web bin/rails tailwindcss:watch
```

You can use `bin/dev` to start both Rails and Tailwind auto-build processes at once:

```bash
$ docker compose exec -e BINDING=0.0.0.0 web bin/dev
```


## Example Scenarios

This application is based on a Memo model created with the following scaffold:

```bash
$ rails generate scaffold Memo title:string description:text
```

On the server side, flash messages are set in the response. This is the typical usage of flash messages in Rails.

| Scenario           | Steps                                 | Expected Flash type and message                        |
|--------------------|---------------------------------------|-------------------------------------------------------|
| Create Success     | Enter title/description and save       | notice: "Created successfully."                       |
| Validation Failure | Submit empty form                      | alert: "Could not create."                            |
| Edit Success       | Edit and save existing memo            | notice: "Updated successfully."                       |
| Delete Success     | Click Destroy button                   | notice: "Destroyed successfully."                     |

The index (list) page includes a filter form. This is implemented with a Turbo Frame, so only the list frame is updated, not the whole page.

| Scenario           | Steps                                 | Expected Flash type and message                        |
|--------------------|---------------------------------------|-------------------------------------------------------|
| offset out of range| Enter an offset larger than the total count and click Apply | warning: "No memos found for the specified offset; it may be out of range." |
| limit exceeded     | Enter a limit larger than the internal cap (10) and click Apply | alert: "limit must be <= 10"                  |


Client-side messages are also implemented and can be checked as follows:

| Scenario           | Steps                                 | Expected Flash type and message                        |
|--------------------|---------------------------------------|-------------------------------------------------------|
| forbidden string   | Submit the string "test"              | alert: "Submission blocked: contains forbidden word."  |


## Extensions (Optional)

Currently, as an extension, when a `turbo:fetch-request-error` occurs (such as network disconnection), a general error message is generated and displayed.

To simulate this, select "Offline" in the "Network" tab of the browser console (e.g., Chrome).

Similarly, if an HTTP response error occurs when submitting a form and no flash is embedded in the response, a general error message is generated instead.

Both use the main features of `flash_messages.js` and are included and configured accordingly.

(These parts may be separated into another module in the future.)


## License

This project is licensed under the **0BSD (Zero-Clause BSD)** license. See `LICENSE` for details.
