
Japanese version: [README.ja.md](README.ja.md)

# Unified Flash Messages Example

This repository is a demo application that implements the Rails gem `flash-unified`, which provides a unified flash message rendering mechanism usable from both the server side and client side in Rails applications.

Up to version v0.2.0, the project focused on implementing ideas for handling flash messages. Afterward, the reusable gem `flash-unified` was created, and this demo app was refactored to import and use that gem.

For the concept and implementation background, please refer to the `flash-unified` gem repository:

[https://github.com/hiroaki/flash-unified](https://github.com/hiroaki/flash-unified)

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


Client-side messages are implemented and can be checked as follows:

| Scenario           | Steps                                 | Expected Flash type and message                        |
|--------------------|---------------------------------------|-------------------------------------------------------|
| forbidden string   | Submit the string "test"              | alert: "Submission blocked: contains forbidden word."  |


In addition, when the `turbo:fetch-request-error` event occurs, such as during a network disconnection, a general error message is generated and displayed. To simulate a network disconnection, you can select "Offline" in the "Network" tab of the browser console in Chrome.


## License

This project is licensed under the **0BSD (Zero-Clause BSD)** license. See `LICENSE` for details.
