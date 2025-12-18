import os
from functools import cache
from http import HTTPStatus

import uvicorn
from fastapi import FastAPI, HTTPException, Request
from fastapi.responses import Response
from fastapi.staticfiles import StaticFiles
from starlette.middleware.base import BaseHTTPMiddleware

# Ensure we're serving from the /workspace directory
workspace_dir = "/workspace"
vnc_password_file = "/root/.vnc/password.txt"


class WorkspaceDirMiddleware(BaseHTTPMiddleware):
    async def dispatch(self, request: Request, call_next):
        # Check if workspace directory exists and recreate if deleted
        if not os.path.exists(workspace_dir):
            print(f"Workspace directory {workspace_dir} not found, recreating...")
            os.makedirs(workspace_dir, exist_ok=True)
        return await call_next(request)


app = FastAPI()


@cache
def get_vnc_password():
    with open(vnc_password_file, "r") as f:
        return f.read().strip()


@app.get("/auth")
async def auth(request: Request):
    """Auth endpoint to validate password and set cookie"""
    # Check if auth cookie already exists
    if request.cookies.get("sandbox_auth"):
        return Response(status_code=HTTPStatus.OK)

    # Get password from query params
    password = request.query_params.get("password")

    # Validate password matches env var
    if not password or password != get_vnc_password():
        raise HTTPException(status_code=HTTPStatus.UNAUTHORIZED, detail="Invalid password")

    # Daytona and E2B provide https, our development EC2 does not so setting the cookies do not work
    # This enables us to use cookies for auth and VSCode and TTy will then work
    # TODO: remove this once we have a proxy and https
    is_secure = request.url.scheme == "https"
    # Password valid, set cookie and return success
    response = Response(status_code=HTTPStatus.OK)
    response.set_cookie(
        key="sandbox_auth", value="authenticated", httponly=True, secure=is_secure, expires=3600
    )
    return response


app.add_middleware(WorkspaceDirMiddleware)

# Initial directory creation
os.makedirs(workspace_dir, exist_ok=True)
app.mount("/", StaticFiles(directory=workspace_dir, html=True), name="site")


# This is needed for the import string approach with uvicorn
if __name__ == "__main__":
    print(f"Starting server with auto-reload, serving files from: {workspace_dir}")
    # Don't use reload directly in the run call
    uvicorn.run("server:app", host="0.0.0.0", port=8080, reload=True)
