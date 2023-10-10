/++
Module for loading and managing sound (in particular, playback).

Macros:
    LREF = <a href="#$1">$1</a>
    HREF = <a href="$1">$2</a>
    PHOBREF = <a href="https://dlang.org/phobos/$1.html#$2">$2</a>

Authors: $(HREF https://github.com/TodNaz,TodNaz)
Copyright: Copyright (c) 2020 - 2021, TodNaz.
License: $(HREF https://github.com/TodNaz/Tida/blob/master/LICENSE,MIT)
+/
module tida.sound;

export:

import bindbc.openal;
import std.exception : enforce;
import tida.runtime;

__gshared
{
    Device adevice;
}

/++
Function to load a library of sound and music playback.

Throws:
$(PHOBREF object,Exception) if the library was not found on the system.
+/
void initSoundlibrary() @trusted
{
    enforce!Exception(loadOpenAL() != ALSupport.noLibrary,
    "Library \"OpenAL\" was not found.");

    adevice = new Device();
    adevice.open();
}

/++
Sound manager. It is a device from where you can adjust the position
of the listener and other operations.
+/
Device soundManager() @trusted
{
    return adevice;
}

/++
Audio playback context. Some global parameters of sound and music are set from it.
+/
class Device
{
    import tida.vector;

private:
    ALCdevice* _device;
    ALCcontext* _context;

    uint[] sources;

export @trusted:
    /// Device object.
    @property ALCdevice* device()
    {
        return _device;
    }

    /// Context object.
    @property ALCcontext* context()
    {
        return _context;
    }

    void allocSource(ref uint source) @trusted
    {
        alGenSources(1, &source);
        sources ~= source;
    }

    void destroySource(ref uint source)
    {
        import std.algorithm : remove;

        alDeleteSources(1, &source);
        sources = sources.remove!(a => a == source);
    }

    /// Stops all sound sources
    void stopAll() @trusted
    {
        foreach (source; sources)
            alSourceStop(source);
    }

    /++
    The position of the main listener in space.
    +/
    @property void position(Vector!float value)
    {
        alListener3f(AL_POSITION, value.x, value.y, 0.0f);
    }

    /// ditto
    @property Vector!float position()
    {
        float[3] pos;

        alGetListenerfv(AL_POSITION, &pos[0]);

        return vec!float(pos[0 .. 2]);
    }

    /++
    Opens and prepares the device for work.

    Throws:
    $(PHOBREF object,Exception) If the device was not initialized and
    an error occurred.
    +/
    void open()
    {
        _device = alcOpenDevice(null);
        enforce!Exception(_device, "Device is not a open!");

        _context = alcCreateContext(_device, null);
        enforce!Exception(alcMakeContextCurrent(_context), "Context is not a create!");

        ALfloat[] listenerOri = [ 0.0f, 0.0f, 1.0f, 0.0f, 1.0f, 0.0f ];

        alListener3f(AL_POSITION, 0, 0, 0);
        alListener3f(AL_VELOCITY, 0, 0, 0);
        alListenerfv(AL_ORIENTATION, cast(float*) listenerOri);
    }

    /++
    Closes the device.
    (Make sure that all sounds have been cleared from memory before this).
    +/
    void close()
    {
        alcMakeContextCurrent(null);
        alcDestroyContext(context);
        alcCloseDevice(device);
    }

    ~this() @safe
    {
        stopAll();
        close();
    }
}

/++
Sound module and also music (if you set the repeat parameter).
+/
class Sound
{
    import std.datetime;
    import tida.vector;

private:
    uint _source;
    uint _buffer;
    ubyte[] _bufferData;
    Vecf _position;

    bool _isPlay;

export @trusted:
    /++
    Buffer identificator.
    +/
    @property uint bufferID()
    {
        return _buffer;
    }

    /++
    Buffer identificator.
    +/
    @property void bufferID(uint value)
    {
        _buffer = value;
    }

    /// Allocates space for the source and buffer.
    this()
    {
        allocateBuffer();
        allocateSource();
    }

    /// Allocates space for the buffer.
    void allocateBuffer()
    {
        alGenBuffers(1, &_buffer);
    }

    /// Allocates space for the source.
    void allocateSource()
    {
        soundManager.allocSource(_source);

        alSourcef(_source, AL_PITCH, 1.0f);
        alSourcef(_source, AL_GAIN, 1.0f);
        alSource3f(_source, AL_POSITION, 0, 0, 0);
        alSource3f(_source, AL_VELOCITY, 0, 0, 0);
        alSourcei(_source, AL_LOOPING, AL_FALSE);
    }

    /++
    Inserts music data into the buffer for further playback.

    Params:
        wave = Sound data.
    +/
    void bind(Wav wave)
    {
        const format = wave.numChannels > 1 ?
            (wave.bitsPerSample == 8 ? AL_FORMAT_STEREO8 : AL_FORMAT_STEREO16) :
            (wave.bitsPerSample == 8 ? AL_FORMAT_MONO8 : AL_FORMAT_MONO16);

        _bufferData = wave.data;

        alBufferData(_buffer, format, cast(void*) _bufferData,
        cast(int) _bufferData.length, wave.sampleRate);
    }

    /++
    The source enters a buffer of sound or music for further playback.
    +/
    void inSourceBindBuffer()
    {
        alSourcei(_source, AL_BUFFER, _buffer);
    }

    void destroy()
    {
        soundManager.destroySource(_source);
    }

    /++
    Load sound from file.

    Params:
        path = The path to the sound file.
    +/
    void load(string path)
    {
        import std.path;

        allocateSource();

        switch (path.extension)
        {
            case ".wav":
                Wav wave = new Wav();
                wave.load(path);
                bind(wave);
                inSourceBindBuffer();
            break;

            case ".mp3":
                Wav wave = new MP3();
                wave.load(path);
                bind(wave);
                inSourceBindBuffer();
            break;

            default:
                return;
        }
    }

    /++
    The position of the sound in the plane.
    +/
    @property void position(Vector!float value)
    {
        alSource3f(_source, AL_POSITION, value.x, value.y, 0.0f);
    }

    /// ditto
    @property Vector!float position()
    {
        float[3] pos;
        alGetSourcefv(_source, AL_POSITION, &pos[0]);

        return vec!float(pos[0 .. 2]);
    }

    /++
    Sound source volume control.

    Params:
        volume = Volume source [0 .. 100].
    +/
    @property void volume(uint volume)
    in(volume <= 100)
    do
    {
        alSourcef(_source, AL_GAIN, cast(float) volume / 100);
    }

    /++
    Do I need to repeat the sample.
    +/
    @property void loop(bool value)
    {
        alSourcei(_source, AL_LOOPING, value ? AL_TRUE : AL_FALSE);
    }

    /++
    Starts playing the sound
    (if the sound is already played, then the sound will start acting back).
    +/
    void play()
    {
        alSourcePlay(_source);
    }

    /++
    Stops playing sound or music.
    +/
    void stop()
    {
        alSourceStop(_source);
    }

    /++
    Pauses playback sound, keeping its position.
    +/
    void pause()
    {
        alSourcePause(_source);
    }

    /++
    Resume playback sound. (Alias $(LREF play))
    +/
    void resume()
    {
        alSourcePlay(_source);
    }

    /++
    Estimated sound time (duration) in seconds.
    +/
    @property Duration duration()
    {
        int size;
        int chn;
        int bits;
        int fq;

        alGetBufferi(_buffer,AL_SIZE,&size);
        alGetBufferi(_buffer,AL_CHANNELS,&chn);
        alGetBufferi(_buffer,AL_BITS,&bits);
        alGetBufferi(_buffer,AL_FREQUENCY,&fq);

        return dur!"seconds"(
            (size * 8 / (chn * bits)) / fq
        );
    }

    /++
    The current position of the music in seconds.
    +/
    @property Duration currentDuration()
    {
        int chn;
        int bits;
        int fq;
        float currSample = 0.0f;

        alGetBufferi(_buffer, AL_CHANNELS, &chn);
        alGetBufferi(_buffer, AL_BITS, &bits);
        alGetBufferi(_buffer, AL_FREQUENCY, &fq);

        alGetSourcef(_source, AL_SAMPLE_OFFSET, &currSample);

        return dur!"seconds"(
            ((cast(int) currSample) * 32 / (chn * bits)) / fq
        );
    }

    /// ditto
    @property void currentDuration(Duration duration)
    {
        int chn;
        int bits;
        int fq;

        alGetBufferi(_buffer, AL_CHANNELS, &chn);
        alGetBufferi(_buffer, AL_BITS, &bits);
        alGetBufferi(_buffer, AL_FREQUENCY, &fq);

        alSourcef(_source, AL_SEC_OFFSET, duration.total!"seconds");
    }

    /// Sound gain effect (range 0 .. 1)
    @property void gain(float value)
    {
        alSourcef(_source, AL_GAIN, value);
    }

    /// Sound speed (0.25 .. 2)
    @property void pitch(float value)
    {
        alSourcef(_source, AL_PITCH, value);
    }

    /++
    Shows if music is currently playing.
    +/
    bool isPlay()
    {
        int state;
        alGetSourcei(_source,AL_SOURCE_STATE,&state);

        return state == AL_PLAYING;
    }

    /++
    shows if music is currently paused.
    +/
    bool isPaused()
    {
        int state;
        alGetSourcei(_source,AL_SOURCE_STATE,&state);

        return state == AL_PAUSED;
    }

    /++
    Based on sound, reproduces a different sound using the same buffer,
    but with different sources. This makes it possible to play the same
    sound without stopping each other.
    +/
    Sound copySource()
    {
        Sound sound = new Sound();
        sound.bufferID = bufferID;
        sound.inSourceBindBuffer();

        return sound;
    }

    ~this()
    {
        destroy();
    }

    /++
    Stops all sound sources
    +/
    static void stopAll() @trusted
    {
        soundManager.stopAll();
    }
}

private T byteTo(T)(ubyte[] bytes) @trusted
{
    T data = T.init;
    foreach(i; 0 .. bytes.length) data = cast(T) (((data & 0xFF) << 8) + bytes[i]);

    return data;
}

/++
Object describing the audio format WAV.
+/
class Wav
{
    import std.file;

    export
    {
        ubyte audioFormat; /// Audio format.
        ushort numChannels; /// The number of channels.
        uint sampleRate; /// Channel speed.
        uint byteRate; /// Channel speed. in bytes.
        ushort blockAlign; /// Block Align
        ushort bitsPerSample; /// Significant Bits Per Sample
        ubyte[] data; /// Sound data
    }

    /++
    Loads an audio format from a file.

    Params:
        file = The path to the file.
    +/
    void load(string file) @trusted
    {
        fromData(read(file));
    }

    void fromData(void[] cdat) @trusted
    {
        ubyte[] dat = cast(ubyte[]) cdat;

        if(cast(string) dat[0 .. 4] != "RIFF")
            throw new Exception("It not a sound file!");

        ubyte[] cDat = dat[20 .. 36];
        audioFormat = cDat[0 .. 1].byteTo!ubyte;
        numChannels = cDat[1 .. 3].byteTo!ushort;
        sampleRate = cDat[3 .. 7].byteTo!uint;
        byteRate = cDat[7 .. 11].byteTo!uint;
        blockAlign = cDat[11 .. 13].byteTo!ushort;
        bitsPerSample = cDat[13 .. 15].byteTo!ushort;

        data = dat[44 .. $];
    }

    /// Dynamic copy
    Wav dup() @safe
    {
        Wav dupped = new Wav();
        dupped.audioFormat = audioFormat;
        dupped.numChannels = numChannels;
        dupped.sampleRate = sampleRate;
        dupped.byteRate = byteRate;
        dupped.blockAlign = blockAlign;
        dupped.bitsPerSample = bitsPerSample;
        dupped.data = data.dup;

        return dupped;
    }
}

/++
Decoder for mp3.
+/
class MP3 : Wav
{
    import mp3decoder;
    import mp3decoderex;

    override void load(string path) @trusted
    {
        import core.stdc.stdlib : free; 

        mp3dec_t mp3d;
        mp3dec_file_info_t info = mp3dec_load(mp3d,path,null,null);

        audioFormat = 1;
        numChannels = cast(ushort) info.channels;
        sampleRate = info.hz;
        bitsPerSample = cast(ushort) info.avg_bitrate_kbps;

        data = cast(ubyte[]) info.buffer[0 .. info.samples].dup;
        free(cast(void*) info.buffer);
    }

    override void fromData(void[] cdat) @trusted
    {
        import core.stdc.stdlib : free;   

        mp3dec_t mp3d;
        mp3dec_file_info_t info;
        mp3dec_load_buf(mp3d, cast(ubyte[]) cdat, info, null, null);

        audioFormat = 1;
        numChannels = cast(ushort) info.channels;
        sampleRate = info.hz;
        bitsPerSample = cast(ushort) info.avg_bitrate_kbps;

        data = cast(ubyte[]) info.buffer[0 .. info.samples].dup;
        free(cast(void*) info.buffer);
    }
}
