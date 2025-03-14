# agent_coverage

This is a code coverage-improving LLM agent for MoonBit-based projects.

To run it in `dev` mode, install required NPM dependencies with `npm install`,
and then execute the following command:

```bash
npm run dev
```

To run in `prod` mode, just replace `dev` in the command above with `prod`.

The configuration of this project relies entirely on environment variables and/or the `.env` file.
You may use the `.env.example` file as a reference.

In particular, if `AGENT_COVERAGE_USE_OTEL` is set to `1`, the agent will use OpenTelemetry
to export logs to the specified endpoint.
Otherwise, the agent will use the default logging mechanism and print JSON lines to the console,
and in this case, you might want to prettify these lines like so:

```bash
npm run dev | npx pino-pretty
```
