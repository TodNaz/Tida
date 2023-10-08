module tida.sdlruntime;

import bindbc.sdl;
import tida.runtime;
export:

export class TidaRuntime : ITidaRuntime
{
    string[] args;

    version(Windows)
    {
        import core.sys.windows.windows;

        HINSTANCE cuda;
    }

@safe:
    /++
    Connects to the window manager.

    Throws:
    $(OBJECTREF Exception) If the libraries were not installed on the machine 
    being started or they were damaged. And also if the connection to the 
    window manager was not successful (for example, there is no such component 
    in the OS or the connection to an unknown window manager is not supported).
    +/
    void connectToWndMng() @trusted
    {
        auto sb = loadSDL();
        if (sb == SDLSupport.badLibrary ||
            sb == SDLSupport.noLibrary)
            throw new Exception("SDL Init error!");

        if (SDL_Init(SDL_INIT_VIDEO) < 0)
            throw new Exception("Error initialized sdl!");

        version(Windows)
        {
            cuda = LoadLibraryA("nvcuda.dll");
            if (cuda !is null) {}
        }
                    
        SDL_GL_SetAttribute(SDL_GL_CONTEXT_FLAGS, SDL_GL_CONTEXT_FORWARD_COMPATIBLE_FLAG);
        SDL_GL_SetAttribute(SDL_GL_CONTEXT_PROFILE_MASK, SDL_GL_CONTEXT_PROFILE_CORE);
        SDL_GL_SetAttribute(SDL_GL_DOUBLEBUFFER, 1);
        SDL_GL_SetAttribute(SDL_GL_DEPTH_SIZE, 24);
        SDL_GL_SetAttribute(SDL_GL_STENCIL_SIZE, 8);
        SDL_GL_SetAttribute(SDL_GL_CONTEXT_MAJOR_VERSION, 3);
        SDL_GL_SetAttribute(SDL_GL_CONTEXT_MINOR_VERSION, 3);
        SDL_GL_SetAttribute(SDL_GL_ACCELERATED_VISUAL, 1);
    }

    /++
    Closes the session with the window manager.
    +/
    void closeWndMngSession() @trusted
    {
        SDL_Quit();
    }

    /++
    Arguments given to the program.
    +/
    @property string[] mainArguments()
    {
        return args;
    }

    /++
    Accepts program arguments for subsequent operations with them.
    +/
    void acceptArguments(string[] arguments)
    {
        this.args = arguments;
    }

    uint[2] monitorSize() @trusted
    {
        SDL_DisplayMode DM;
        SDL_GetCurrentDisplayMode(0, &DM);

        return [cast(uint) DM.w, cast(uint) DM.h];
    }
}