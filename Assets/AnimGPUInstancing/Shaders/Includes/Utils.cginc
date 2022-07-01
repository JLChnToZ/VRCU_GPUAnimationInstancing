#ifndef _AnimationGpuInstancing
#define _AnimationGpuInstancing

float4 GetUV(float index, float4 texelSize)
{
    float row = floor(index * texelSize.x) + 0.5;
    float col = floor(index % texelSize.z) + 0.5;

    return float4(col * texelSize.x, row * texelSize.y, 0.0, 0.0);
}

float4 GetTexLerp(float currentIndex, float startIndex, float maxIndex, float indexStep, float indexOffset, sampler2D tex, float4 texelSize)
{
    return lerp(
        tex2Dlod(tex, GetUV(trunc(floor(currentIndex) % maxIndex + startIndex) * indexStep + indexOffset, texelSize)),
        tex2Dlod(tex, GetUV(trunc(ceil(currentIndex) % maxIndex + startIndex) * indexStep + indexOffset, texelSize)),
        frac(currentIndex)
    );
}

float4x4 GetMatrix(float currentIndex, float startIndex, float maxIndex, float indexStep, float boneIndex, sampler2D tex, float4 texelSize)
{
    float4 row0 = GetTexLerp(currentIndex, startIndex, maxIndex, indexStep, boneIndex * 3, tex, texelSize);
    float4 row1 = GetTexLerp(currentIndex, startIndex, maxIndex, indexStep, boneIndex * 3 + 1, tex, texelSize);
    float4 row2 = GetTexLerp(currentIndex, startIndex, maxIndex, indexStep, boneIndex * 3 + 2, tex, texelSize);
    float4 row3 = float4(0.0, 0.0, 0.0, 1.0);

    return float4x4(row0, row1, row2, row3);
}

float4 MultiplyBones(float4 src, float4x4 bone1Mat, float4x4 bone2Mat, float4x4 bone3Mat, float4x4 bone4Mat, float4 boneWeight)
{
    return mul(bone1Mat, src) * boneWeight.x + 
        mul(bone2Mat, src) * boneWeight.y + 
        mul(bone3Mat, src) * boneWeight.z + 
        mul(bone4Mat, src) * boneWeight.w;
}

float rand(float2 n)
{
    return frac(sin((n.x * 1e2 + n.y * 1e4 + 1475.4526) * 1e-4) * 1e6);
}

#endif 