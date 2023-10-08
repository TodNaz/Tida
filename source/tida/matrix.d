/++
Matrix management module.

Macros:
    LREF = <a href="#$1">$1</a>
    HREF = <a href="$1">$2</a>
    IDENTITY_IMG = <img src="https://latex.codecogs.com/svg.image?I_{n}&space;=&space;\begin{bmatrix}&space;1&&space;0&space;&&space;0&space;&&space;0&space;\\&space;0&&space;1&space;&&space;0&space;&&space;0&space;\\&space;0&&space;0&space;&&space;1&space;&&space;0&space;\\&space;0&&space;0&space;&&space;0&space;&&space;1&space;\\\end{bmatrix}" title="I_{n} = \begin{bmatrix} 1& 0 & 0 & 0 \\ 0& 1 & 0 & 0 \\ 0& 0 & 1 & 0 \\ 0& 0 & 0 & 1 \\\end{bmatrix}" />
    TRANSLATE_IMG = <img src="https://latex.codecogs.com/svg.image?\begin{bmatrix}&space;1&space;&&space;0&space;&&space;0&space;&&space;x&space;\\&space;0&space;&&space;1&space;&&space;0&space;&&space;y&space;\\&space;0&space;&&space;0&space;&&space;1&space;&&space;z&space;\\&space;0&space;&&space;0&space;&&space;0&space;&&space;1&space;\\\end{bmatrix}" title="\begin{bmatrix} 1 & 0 & 0 & x \\ 0 & 1 & 0 & y \\ 0 & 0 & 1 & z \\ 0 & 0 & 0 & 1 \\\end{bmatrix}" />
    SCALE_IMG = <img src="https://latex.codecogs.com/svg.image?\begin{bmatrix}&space;x&space;&&space;0&space;&&space;0&space;&&space;0&space;\\&space;0&space;&&space;y&space;&&space;0&space;&&space;0&space;\\&space;0&space;&&space;0&space;&&space;z&space;&&space;0&space;\\&space;0&space;&&space;0&space;&&space;0&space;&&space;1&space;\\\end{bmatrix}" title="\begin{bmatrix} x & 0 & 0 & 0 \\ 0 & y & 0 & 0 \\ 0 & 0 & z & 0 \\ 0 & 0 & 0 & 1 \\\end{bmatrix}" />
    ROTATE_IMG = <img src="https://latex.codecogs.com/svg.image?xfactor&space;=&space;\begin{bmatrix}&space;1&space;&&space;0&space;&&space;0&space;&&space;0&space;\\&space;0&space;&&space;cos&space;\o&space;&&space;-sin&space;\o&space;&&space;0&space;\\&space;0&space;&&space;sin&space;\o&space;&&space;cos&space;\o&space;&&space;0&space;\\&space;0&space;&&space;0&space;&&space;0&space;&&space;1&space;\\\end{bmatrix},y-factor&space;=\begin{bmatrix}&space;cos\psi&space;&&space;0&space;&&space;sin\psi&space;&&space;0&space;\\&space;0&space;&&space;1&space;&&space;0&space;&&space;0&space;\\&space;-sin\psi&space;&&space;0&space;&&space;cos\psi&space;&space;&&space;0&space;\\&space;0&space;&&space;0&space;&&space;0&space;&&space;1&space;\\\end{bmatrix},z-factor=&space;\begin{bmatrix}&space;cos\chi&space;&space;&&space;-sin\chi&space;&&space;0&space;&&space;0&space;\\&space;sin\chi&space;&&space;cos\chi&space;&&space;0&space;&&space;0&space;\\&space;0&space;&&space;0&space;&&space;1&space;&&space;0&space;\\&space;0&space;&&space;0&space;&&space;0&space;&&space;1&space;\\\end{bmatrix}" title="xfactor = \begin{bmatrix} 1 & 0 & 0 & 0 \\ 0 & cos \o & -sin \o & 0 \\ 0 & sin \o & cos \o & 0 \\ 0 & 0 & 0 & 1 \\\end{bmatrix},y-factor =\begin{bmatrix} cos\psi & 0 & sin\psi & 0 \\ 0 & 1 & 0 & 0 \\ -sin\psi & 0 & cos\psi & 0 \\ 0 & 0 & 0 & 1 \\\end{bmatrix},z-factor= \begin{bmatrix} cos\chi & -sin\chi & 0 & 0 \\ sin\chi & cos\chi & 0 & 0 \\ 0 & 0 & 1 & 0 \\ 0 & 0 & 0 & 1 \\\end{bmatrix}" />

Authors: $(HREF https://github.com/TodNaz,TodNaz)
Copyright: Copyright (c) 2020 - 2021, TodNaz.
License: $(HREF https://github.com/TodNaz/Tida/blob/master/LICENSE,MIT)
+/
module tida.matrix;

alias mat4 = float[4][4]; /// Matrix alias

/++
    A square matrix, the elements of the main diagonal of which are equal to one
    of the field, and the rest are equal to zero.

    $(IDENTITY_IMG)
+/
@property float[4][4] identity() @safe nothrow pure
{
    return  [
                [1, 0, 0, 0],
                [0, 1, 0, 0],
                [0, 0, 1, 0],
                [0, 0, 0, 1]
            ];
}

/++
Increases the matrix by a specified factor along the specified axes.

Params:
    x = X-axis scaling factor.
    y = Y-axis scaling factor.
    z = Z-axis scaling factor.

Returns:
    Scaling matrix.

See_Also:
    $(HREF https://en.wikipedia.org/wiki/Scaling_(geometry), Scaling (geometry) - Wikipedia.)

$(SCALE_IMG)
+/
float[4][4] scaleMat(float x, float y, float z = 1.0f) @safe nothrow pure
{
    float[] v = [x, y, z, 1.0f];
    float[4][4] mat = identity();

    for (int i = 0; i < 4; ++i)
        for (int j = 0; j + 1 < 4; ++j)
            mat[i][j] *= v[j];

    return mat;
}

/++
Increases the matrix by a specified factor along the specified axes.

Params:
    mat = Matrix to be scaled.
    x = X-axis scaling factor.
    y = Y-axis scaling factor.
    z = Z-axis scaling factor.

Returns:
    Scaling matrix.

See_Also:
    $(HREF https://en.wikipedia.org/wiki/Scaling_(geometry), Scaling (geometry) - Wikipedia.)

$(SCALE_IMG)
+/
float[4][4] scale(float[4][4] mat, float x, float y, float z = 1.0f) @safe nothrow pure
{
    return mulmat(mat, scaleMat(x, y, z));
}

/++
Moves the matrix along the specified axes by the specified amount.

Params:
    x = X-axis move factor.
    y = Y-axis move factor.
    z = Z-axis move factor.

Returns:
    Moved matrix.

See_Also:
    $(HREF https://en.wikipedia.org/wiki/Translation_(geometry), Translation (geometry) - Wikipedia)

$(TRANSLATE_IMG)
+/
float[4][4] translation(float x, float y, float z) @safe nothrow pure
{
    auto mat = identity();

    mat[3][0] = x;
    mat[3][1] = y;
    mat[3][2] = z;

    return mat;
}

/++
Moves the matrix provided in the arguments along the given axes with the
given values.

Params:
    mat = The matrix to be moved.
    x = X-axis move factor.
    y = Y-axis move factor.
    z = Z-axis move factor.

Returns:
    Matrix that was previously cast in the matrix and is now moved by the function.

See_Also:
    $(HREF https://en.wikipedia.org/wiki/Translation_(geometry), Translation (geometry) - Wikipedia)

$(TRANSLATE_IMG)
+/
float[4][4] translate(float[4][4] mat, float x, float y, float z) @safe nothrow pure
{
    return mulmat(mat, translation(x, y, z));
}

/++
Gives the rotation matrix.

Params:
    angle = Angle rotation.
    x = X-axis rotate factor.
    y = Y-axis rotate factor.
    z = Z-axis rotate factor.

Returns:
    Rotation matrix.

Also_See:
    $(HREF https://en.wikipedia.org/wiki/Rotation_matrix, Rotation matrix - Wikipedia)

$(ROTATE_IMG)
+/
float[4][4] rotateMat(float angle, float x, float y, float z) @safe nothrow pure
{
    import std.math;

    float[4][4] res = identity();

    const float c = cos(angle);
    const oneMinusC = 1 - c;
    const float s = sin(angle);

    res[0][0] = x * x * oneMinusC + c;
    res[0][1] = x * y * oneMinusC - z * s;
    res[0][2] = x * z * oneMinusC + y * s;
    res[1][0] = y * x * oneMinusC + z * s;
    res[1][1] = y * y * oneMinusC + c;
    res[1][2] = y * z * oneMinusC - x * s;
    res[2][0] = z * x * oneMinusC - y * s;
    res[2][1] = z * y * oneMinusC + x * s;
    res[2][2] = z * z * oneMinusC + c;

    return res;
}

/++
Gives the rotation matrix.

Params:
    mat = Rotation matrix.
    angle = Angle rotation.
    x = X-axis rotate factor.
    y = Y-axis rotate factor.
    z = Z-axis rotate factor.

Returns:
    Rotation matrix.

Also_See:
    $(HREF https://en.wikipedia.org/wiki/Rotation_matrix, Rotation matrix - Wikipedia)

$(ROTATE_IMG)
+/
float[4][4] rotateMat(float[4][4] mat, float angle, float x, float y, float z) @safe nothrow pure
{
    return mulmat(mat, rotateMat(angle, x, y, z));
}

/++
Euler method rotation matrix.

Params:
    roll = Roll-Axis.
    pitch = Pitch-Axis.
    yaw = Yaw-Axis.

Returns:
    Rotated matrix.

See_Also:
    $(HREF https://en.wikipedia.org/wiki/Rotation_matrix, Rotation matrix - Wikipedia)
+/
float[4][4] eulerRotateMat(float roll, float pitch, float yaw) @safe nothrow pure
{
    import std.math;

    float[4][4] xres = identity();
    float[4][4] yres = identity();
    float[4][4] zres = identity();

    immutable ct = [cos(roll), cos(pitch), cos(yaw)];
    immutable st = [sin(roll), sin(pitch), sin(yaw)];

    xres[0][0] = ct[0];
    xres[0][1] = st[0];
    xres[1][0] = -st[0];
    xres[1][1] = ct[0];

    yres[0][0] = ct[1];
    yres[0][2] = -st[1];
    yres[2][0] = st[1];
    yres[2][2] = ct[1];

    zres[0][0] = ct[2];
    zres[0][1] = st[2];
    zres[1][0] = -st[2];
    zres[1][1] = ct[2];

    mat4 result = identity();

    result = mulmat(result, xres);
    result = mulmat(result, yres);
    result = mulmat(result, zres);

    return result;
}

/++
Euler method rotation matrix.

Params:
    mat = Rotation matrix.
    roll = Roll-Axis.
    pitch = Pitch-Axis.
    yaw = Yaw-Axis.

Returns:
    Rotated matrix.

See_Also:
    $(HREF https://en.wikipedia.org/wiki/Rotation_matrix, Rotation matrix - Wikipedia)
+/
float[4][4] eulerRotate(float[4][4] mat, float roll, float pitch, float yaw) @safe nothrow pure
{
    return mulmat(mat, eulerRotateMat(roll, pitch, yaw));
}

/++
Multiply two matrices.

Params:
    a = First matrix.
    b = Second matrix.

Returns:
    Multiple matrix.

See_Also:
    $(HREF https://en.wikipedia.org/wiki/Matrix_multiplication, Matix multiplication - Wikipedia)
+/
float[4][4] mulmat(float[4][4] a, float[4][4] b) @safe nothrow pure
{
    float[4][4] result = 0.0f;

    for (int i = 0; i < 4; ++i)
    {
        for (int j = 0; j < 4; ++j)
        {
            float sum = 0.0f;
            
            for (int k = 0; k < 4; ++k)
                sum += a[i][k] * b[k][j];

            result[i][j] = sum;
        }
    }

    return result;
}

/// Ortho matrix generate
float[4][4] ortho(float left, float right, float bottom, float top, float zNear = -1.0f, float zFar = 0.0f)
@safe nothrow pure
{
    immutable defl = 0.0f;

    immutable mRL = right - left;
    immutable mTB = top - bottom;
    immutable mFN = zFar - zNear;

    immutable tRL = -(right + left) / mRL;
    immutable tTB = -(top + bottom) / mTB;
    immutable tFN = -(zFar + zNear) / mFN;

    return      [
                    [2 / mRL, defl,  defl,    defl],
                    [defl,  2 / mTB, defl,    defl],
                    [defl,    defl, -2 / mFN, defl],
                    [ tRL,    tTB,   tFN,     1.0f]
                ];
}

float[4][4] orthoLR(float left, float right, float bottom, float top, float zNear = -1.0f, float zFar = 0.0f)
@safe pure nothrow
{
    immutable defl = 0.0f;

    immutable mRL = 1.0f / (right - left);
    immutable mTB = 1.0f / (top - bottom);
    immutable mFN = 1.0f / (zFar - zNear);

    immutable tRL = -(right + left) * mRL;
    immutable tTB = -(top + bottom) * mTB;
    immutable tFN = -(zFar + zNear) / mFN;

    return      [
                    [mRL + mRL, defl,  defl,    defl],
                    [defl,  mTB + mTB, defl,    defl],
                    [defl,    defl, -2 / mFN, defl],
                    [ tRL,    tTB,   -tFN * zNear,     1.0f]
                ];
}

import tida.vector;

/++
Multiple matrix and vector.
+/
Vector!float transform(Vector!float v, mat4 m) @safe nothrow pure
{
    Vector!float result = vec!(float)(0.0f, 0.0f);

    for (size_t i = 0; i < 2; ++i)
    {
        float sum = 0.0f;

        for (size_t j = 0; j < 2; ++j)
        {
            sum += m[i][j] * v[j];
        }

        result[i] = sum;
    }

    return result;
}
