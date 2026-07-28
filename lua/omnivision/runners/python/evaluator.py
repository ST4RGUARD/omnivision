import io
import contextlib

# Persistent execution context
STATE = {
    "__builtins__": __builtins__,
}


def evaluate(request):
    code = request.get("code", "")
    kind = request.get("kind", "expression")
    line = request.get("cursor_line", 0)

    contexts = request.get("contexts", [])

    try:
        if kind != "program":
            for context in contexts:
                if context.strip():
                    exec(context, STATE)

        if kind == "expression":
            text = evaluate_expression(code)

        elif kind == "statement":
            text = evaluate_statement(code)

        elif kind == "function":
            text = evaluate_function(code)

        elif kind == "return":
            text = evaluate_return(code)

        else:
            text = evaluate_program(code)

        return [
            {
                "line": line,
                "kind": "result",
                "text": text,
            }
        ]

    except Exception as e:
        return [
            {
                "line": line,
                "kind": "error",
                "text": str(e),
            }
        ]


def evaluate_expression(code):
    output = io.StringIO()

    with contextlib.redirect_stdout(output):
        result = eval(code, STATE)

    printed = output.getvalue().strip()

    if printed:
        return f"=> {printed}"

    return f"=> {result}"


def evaluate_statement(code):
    output = io.StringIO()

    before = set(STATE.keys())

    with contextlib.redirect_stdout(output):
        exec(code, STATE)

    printed = output.getvalue().strip()

    if printed:
        return f"=> {printed}"

    created = set(STATE.keys()) - before

    if created:
        return f"=> defined {', '.join(created)}"

    return "=> executed (no output)"


def evaluate_function(code):
    output = io.StringIO()

    before = set(STATE.keys())

    with contextlib.redirect_stdout(output):
        exec(code, STATE)

    printed = output.getvalue().strip()

    if printed:
        return f"=> {printed}"

    created_functions = [
        name for name, value in STATE.items() if callable(value) and name not in before
    ]

    if len(created_functions) == 1:
        name = created_functions[0]
        func = STATE[name]

        try:
            with contextlib.redirect_stdout(output):
                result = func()

            printed = output.getvalue().strip()

            if printed:
                return f"=> {printed}"

            if result is None:
                return "=> executed (no output)"

            return f"=> {result}"

        except TypeError:
            return f"=> function {name} requires arguments"

    if created_functions:
        return f"=> functions defined: {', '.join(created_functions)}"

    return "=> function defined"


def evaluate_return(code):
    expression = code.strip()

    if expression.startswith("return "):
        expression = expression[7:]

    output = io.StringIO()

    wrapped = f"""
def __omnivision_return():
    return {expression}
"""

    with contextlib.redirect_stdout(output):
        exec(wrapped, STATE)

        result = STATE["__omnivision_return"]()

    printed = output.getvalue().strip()

    if printed:
        return f"=> {printed}"

    return f"=> {result}"


def evaluate_program(code):
    output = io.StringIO()

    with contextlib.redirect_stdout(output):
        exec(code, STATE)

    printed = output.getvalue().strip()

    if printed:
        return f"=> {printed}"

    return "=> executed (no output)"
