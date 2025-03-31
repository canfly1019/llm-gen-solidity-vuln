# llm-gen-solidity-vuln

**🧠 Auto-generate Forge tests for vulnerable and fixed Solidity contracts using LLMs**

This project leverages LLMs (Large Language Models) to automatically generate meaningful Forge-based Foundry test cases from vulnerable and fixed Solidity contracts. It is intended for research and educational purposes, particularly in the domain of smart contract security and benchmarking.

## 🔍 Project Goals

- Automatically generate `.t.sol` test files from annotated Solidity files (`-vulnerability.sol`, `-fixed.sol`)
- Use GPT-based structured output to produce meaningful security-related test cases
- Iterate through each contract and re-generate tests on failure
- Collect a high-quality benchmark dataset for vulnerability detection and patch verification

## 🗂️ Project Structure

```
.
├── src/                        # Original Solidity contracts (vulnerable & fixed)
├── test/                       # Generated test files (.t.sol)
├── scripts/
│   ├── logs.txt                # Execution logs
│   ├── common.py               # Utility functions
│   ├── generate_tests.py       # GPT-based test generator with structured output
│   ├── validate_and_regen.py   # Run test command and regeneration logic
├── output.xlsx                 # Contains vulnerability descriptions by index
├── .env                        # OpenAI API key and other environment config
```

## 🚀 Usage

Run the full test suite with auto-generation:

```bash
python scripts/validate_and_regen.py
```

To resume from a specific contract index (e.g. `4.1`):

```python
start_from = "4.1"
```

## 📋 Test Generation Workflow

1. Iterate through each Solidity file in `src/`
2. For each one, generate or re-use a matching `.t.sol` test file in `test/`
3. Run `forge test` with `--match-path`
4. If compilation fails, pass the error message back to GPT and regenerate
5. After repeated failure, the test file will be deleted

## 🧠 GPT-Based Prompting

The prompt includes:

- Contract source code
- File name and vulnerability index
- Description of the vulnerability (from `output.xlsx`)
- Recompile error messages (if any)
- Clear formatting requirements (`pragma`, `vm.expectRevert`, etc.)

LLM model used: `o3-mini-2025-01-31` (via OpenAI API)

## 📈 Logs

Test attempts, errors, and generation status are saved in:

```
scripts/logs.txt
```

## ✨ Features

- Retry on failure (up to 5 times)
- Delete faulty tests after final attempt
- Easy to control resume point (`start_from`)
- Structured output parsing with Pydantic
- Easy-to-extend GPT logic

## 📚 Related Tools

- [Foundry Book](https://book.getfoundry.sh/)
- [OpenAI API](https://platform.openai.com/docs)
