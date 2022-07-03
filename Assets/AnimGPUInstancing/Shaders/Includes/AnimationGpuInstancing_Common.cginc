#ifndef ANIMATION_GPU_INSTANCING_COMMON_INCLUDED
#define ANIMATION_GPU_INSTANCING_COMMON_INCLUDED
#include "UnityCG.cginc"
#include "./Utils.cginc"

#if _AUDIOLINK
#include "Assets/AudioLink/Shaders/AudioLink.cginc"
#endif

struct appdata_AGI
{
    float4 vertex : POSITION;
    float3 normal : NORMAL;
    float4 texcoord : TEXCOORD0;
    float4 texcoord1 : TEXCOORD1;
    half4 boneIndex : TEXCOORD2;
    fixed4 boneWeight : TEXCOORD3;
    float4 tangent : TANGENT;
    UNITY_VERTEX_INPUT_INSTANCE_ID
};

UNITY_INSTANCING_BUFFER_START(Props)

UNITY_DEFINE_INSTANCED_PROP(uint, _StartFrame)
#define _StartFrame_arr Props 

UNITY_DEFINE_INSTANCED_PROP(uint, _FrameCount)
#define _FrameCount_arr Props

UNITY_DEFINE_INSTANCED_PROP(float, _OffsetSeconds)
#define _OffsetSeconds_arr Props

UNITY_DEFINE_INSTANCED_PROP(uint, _ROOT_MOTION)
#define _ROOT_MOTION_arr Props

UNITY_DEFINE_INSTANCED_PROP(uint, _RepeatStartFrame)
#define _RepeatStartFrame_arr Props 

UNITY_DEFINE_INSTANCED_PROP(uint, _RepeatNum)
#define _RepeatNum_arr Props

#if _AUDIOLINK
UNITY_DEFINE_INSTANCED_PROP(int, _AudioLinkChronotensityIndex)
#define _AudioLinkChronotensityIndex_arr Props

UNITY_DEFINE_INSTANCED_PROP(int, _AudioLinkBand)
#define _AudioLinkBand_arr Props
#endif

UNITY_INSTANCING_BUFFER_END(Props)

sampler2D _AnimTex;
float4 _AnimTex_TexelSize;

sampler2D _RepeatTex;
float4 _RepeatTex_TexelSize;
uint _PixelsPerFrame;  

uint _RepeatMax;   

#define Mat4x4Identity float4x4(1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1)

float _BaseSpeed;
float _TimeNoise;

#if _AUDIOLINK
float _AudioLinkSpeed;
#endif

void CalculateAGI(inout appdata_AGI v)
{
    uint startFrame = UNITY_ACCESS_INSTANCED_PROP(_StartFrame_arr, _StartFrame);
    uint frameCount = UNITY_ACCESS_INSTANCED_PROP(_FrameCount_arr, _FrameCount);
    float offsetSeconds = UNITY_ACCESS_INSTANCED_PROP(_OffsetSeconds_arr, _OffsetSeconds);

    float time = _Time.y * _BaseSpeed + _TimeNoise * (rand(floor(mul(unity_ObjectToWorld, float4(0, 0, 0, 1)).xz * 100.)) - 0.5);
    #if _AUDIOLINK
    if (!AudioLinkIsAvailable())
    {
        time += _Time.y * _AudioLinkSpeed;
    }
    else
    {
        int band = UNITY_ACCESS_INSTANCED_PROP(_AudioLinkBand_arr, _AudioLinkBand) - 1;
        if (band >= 0)
        {
            uint choroIndex = UNITY_ACCESS_INSTANCED_PROP(_AudioLinkChronotensityIndex_arr, _AudioLinkChronotensityIndex);
            time += AudioLinkGetChronoTime(choroIndex, band) * _AudioLinkSpeed;
        }
    }
    #endif

    float offsetFrame = (time + offsetSeconds) * 30.0;

    float4x4 bone1Mat = GetMatrix(offsetFrame, startFrame, frameCount, _PixelsPerFrame, v.boneIndex.x, _AnimTex, _AnimTex_TexelSize);
    float4x4 bone2Mat = GetMatrix(offsetFrame, startFrame, frameCount, _PixelsPerFrame, v.boneIndex.y, _AnimTex, _AnimTex_TexelSize);
    float4x4 bone3Mat = GetMatrix(offsetFrame, startFrame, frameCount, _PixelsPerFrame, v.boneIndex.z, _AnimTex, _AnimTex_TexelSize);
    float4x4 bone4Mat = GetMatrix(offsetFrame, startFrame, frameCount, _PixelsPerFrame, v.boneIndex.w, _AnimTex, _AnimTex_TexelSize);

    float4 pos = MultiplyBones(v.vertex, bone1Mat, bone2Mat, bone3Mat, bone4Mat, v.boneWeight);
    float4 normal = MultiplyBones(float4(v.normal, 0), bone1Mat, bone2Mat, bone3Mat, bone4Mat, v.boneWeight);

    uint _root_motion = UNITY_ACCESS_INSTANCED_PROP(_ROOT_MOTION_arr, _ROOT_MOTION);
    if (_root_motion)
    {
        uint repeatStartFrame = UNITY_ACCESS_INSTANCED_PROP(_RepeatStartFrame_arr, _RepeatStartFrame);
        uint repeatNum  = UNITY_ACCESS_INSTANCED_PROP(_RepeatNum_arr, _RepeatNum);
        repeatNum = max(1, repeatNum);
        float4x4 rootMat = GetMatrix(offsetFrame, repeatStartFrame, repeatNum - 1, 3, 0, _RepeatTex, _RepeatTex_TexelSize);
        pos = mul(rootMat, pos);
        normal = mul(rootMat, normal);
    }

    v.vertex = pos;
    v.normal = normal.xyz;
}
#endif