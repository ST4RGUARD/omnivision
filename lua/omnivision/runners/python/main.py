import sys
import json

from evaluator import evaluate


def main():
    for line in sys.stdin:
        try:
            request = json.loads(line)

            response = {
                "id": request["id"],
                "success": True,
                "observations": evaluate(request),
                "error": None,
            }

        except Exception as e:
            response = {
                "id": 0,
                "success": False,
                "observations": [],
                "error": str(e),
            }

        print(json.dumps(response), flush=True)


if __name__ == "__main__":
    main()
