Shader "AnimationGpuInstancing/Base"
{
    Properties
    {
        _Color ("Color", Color) = (1,1,1,1)
        _MainTex ("Main Texture", 2D) = "white" {}
        _BumpMap("Normal Map", 2D) = "bump" {}
        _Shininess ("Shininess", Range(0.0, 1.0)) = 0.078125

        [NoScaleOffset]_AnimTex("Animation Texture", 2D) = "white" {}


        _StartFrame("Start Frame", Float) = 0 
        _FrameCount("Frame Count", Float) = 1 
        _OffsetSeconds("Offset Seconds", Float) = 0 
        _PixelsPerFrame("Pixels Per Frame", Float) = 0 


        [Toggle]
        _ROOT_MOTION("Apply Root Motion", Float) = 0
        [NoScaleOffset]_RepeatTex("Repeat Texture", 2D) = "white" {}
        _RepeatStartFrame("Repeat Start Frame", Float) = 0
        _RepeatMax("Repeat Max", FLoat) = 1
        _RepeatNum ("Repeat Num", Float) = 1
    
        _BaseSpeed ("Base Speed", Float) = 1
        _TimeNoise ("Position Based Timing Noise", Float) = 0

        [Toggle(_AUDIOLINK)] _AUDIOLINK("AudioLink", Int) = 0
        [Enum(AudioLinkChronotensityType)] _AudioLinkChronotensityIndex ("AudioLink Chronotensity Mode", Int) = 0
        [Enum(None, 0, Bass, 1, Low Mid, 2, High Mid, 3, Treble, 4)]
        _AudioLinkBand ("AudioLink Band", Int) = 0
        _AudioLinkSpeed ("AudioLink Speed", Float) = 1

        [KeywordEnum(UNLIT, REAL)]
        _LIGHTING("Lighting", Float) = 0

        [Toggle] _INSTANCING("Gpu Instancing", Float) = 1
    }

    CustomEditor "AGI_ShaderInspector"

    CGINCLUDE

    #include "UnityCG.cginc"
    #include "Includes/Utils.cginc"

    #pragma shader_feature_local AUDIOLINK

    #if AUDIOLINK
    #include "Assets/AudioLink/Shaders/AudioLink.cginc"
    #endif

    struct appdata
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

    struct v2f
    {
        float2 uv : TEXCOORD0;
        UNITY_FOG_COORDS(1)
        float4 vertex : SV_POSITION;
        float4 normal : NORMAL;
        UNITY_VERTEX_INPUT_INSTANCE_ID
        
        #ifdef _LIGHTING_REAL
        float3 lightDir : TEXCOORD2;
        float3 viewDir : TEXCOORD3;
        #endif 
        
    };

    UNITY_INSTANCING_BUFFER_START(Props)

    UNITY_DEFINE_INSTANCED_PROP(uint, _StartFrame)
    #define _StartFrame_arr Props 

    UNITY_DEFINE_INSTANCED_PROP(uint, _FrameCount)
    #define _FrameCount_arr Props
    
    UNITY_DEFINE_INSTANCED_PROP(uint, _OffsetSeconds)
    #define _OffsetSeconds_arr Props

    UNITY_DEFINE_INSTANCED_PROP(uint, _ROOT_MOTION)
    #define _ROOT_MOTION_arr Props

    UNITY_DEFINE_INSTANCED_PROP(uint, _RepeatStartFrame)
    #define _RepeatStartFrame_arr Props 

    UNITY_DEFINE_INSTANCED_PROP(uint, _RepeatNum)
    #define _RepeatNum_arr Props

    UNITY_DEFINE_INSTANCED_PROP(fixed4, _Color)
    #define _Color_arr Props

    #if AUDIOLINK
    UNITY_DEFINE_INSTANCED_PROP(int, _AudioLinkChronotensityIndex)
    #define _AudioLinkChronotensityIndex_arr Props

    UNITY_DEFINE_INSTANCED_PROP(int, _AudioLinkBand)
    #define _AudioLinkBand_arr Props
    #endif

    UNITY_INSTANCING_BUFFER_END(Props)

    sampler2D _MainTex;
    float4 _MainTex_ST;
    
    sampler2D _BumpMap;

    sampler2D _AnimTex;
    float4 _AnimTex_TexelSize;


    sampler2D _RepeatTex;
    float4 _RepeatTex_TexelSize;
    uint _PixelsPerFrame;  

    uint _RepeatMax;   

    #define Mat4x4Identity float4x4(1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1)

    half _Shininess;
    float4 _LightColor0;

    float _BaseSpeed;
    float _TimeNoise;

    #if AUDIOLINK
    float _AudioLinkSpeed;
    #endif

    v2f vert (appdata v)
    {
        v2f o;

        UNITY_SETUP_INSTANCE_ID(v);
        UNITY_TRANSFER_INSTANCE_ID(v, o);

        uint startFrame = UNITY_ACCESS_INSTANCED_PROP(_StartFrame_arr, _StartFrame);
        uint frameCount = UNITY_ACCESS_INSTANCED_PROP(_FrameCount_arr, _FrameCount);
        float offsetSeconds = UNITY_ACCESS_INSTANCED_PROP(_OffsetSeconds_arr, _OffsetSeconds);

        float time = _Time.y * _BaseSpeed; //  + _TimeNoise * (rand(floor(mul(unity_ObjectToWorld, float4(0, 0, 0, 1)).xz * 100.)) - 0.5);
        #if AUDIOLINK
        if (!AudioLinkIsAvailable())
        {
            time += _Time.y * _AudioLinkSpeed;
        }
        else
        {
            int band = UNITY_ACCESS_INSTANCED_PROP(_AudioLinkBand_arr, _AudioLinkBand) - 1;
            if (band >= 0)
            {
                int choroIndex = UNITY_ACCESS_INSTANCED_PROP(_AudioLinkBand_arr, _AudioLinkChronotensityIndex);
                time += AudioLinkGetChronoTime(choroIndex, band) * _AudioLinkSpeed;
            }
        }
        #endif

        float offsetFrame = (time + offsetSeconds) * 30.0;
        float currentFrame = startFrame + offsetFrame;
        float4x4 bone1Mat = GetMatrix(currentFrame, frameCount, _PixelsPerFrame, v.boneIndex.x, _AnimTex, _AnimTex_TexelSize);
        float4x4 bone2Mat = GetMatrix(currentFrame, frameCount, _PixelsPerFrame, v.boneIndex.y, _AnimTex, _AnimTex_TexelSize);
        float4x4 bone3Mat = GetMatrix(currentFrame, frameCount, _PixelsPerFrame, v.boneIndex.z, _AnimTex, _AnimTex_TexelSize);
        float4x4 bone4Mat = GetMatrix(currentFrame, frameCount, _PixelsPerFrame, v.boneIndex.w, _AnimTex, _AnimTex_TexelSize);

        float4 pos = MultiplyBones(v.vertex, bone1Mat, bone2Mat, bone3Mat, bone4Mat, v.boneWeight);
        float4 normal = MultiplyBones(float4(v.normal, 0), bone1Mat, bone2Mat, bone3Mat, bone4Mat, v.boneWeight);

        uint _root_motion = UNITY_ACCESS_INSTANCED_PROP(_ROOT_MOTION_arr, _ROOT_MOTION);
        if (_root_motion)
        {
            uint repeatStartFrame = UNITY_ACCESS_INSTANCED_PROP(_RepeatStartFrame_arr, _RepeatStartFrame);
            uint repeatNum  = UNITY_ACCESS_INSTANCED_PROP(_RepeatNum_arr, _RepeatNum);
            repeatNum = max(1, repeatNum);
            float currentRepeatIndex = (offsetFrame / frameCount) % repeatNum;
            float currentRepeatFrame = (currentRepeatIndex == 0) ? 0 : repeatStartFrame + currentRepeatIndex - 1;
            float4x4 rootMat = GetMatrix(currentRepeatFrame, repeatNum, 3, 0, _RepeatTex, _RepeatTex_TexelSize);
            pos = mul(rootMat, pos);
            normal = mul(rootMat, normal);
        }

        o.vertex = UnityObjectToClipPos(pos);
        UNITY_TRANSFER_FOG(o,o.vertex);
        o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
        o.normal = normal;

#ifdef _LIGHTING_REAL
            TANGENT_SPACE_ROTATION;
            o.lightDir = normalize(mul(rotation, ObjSpaceLightDir(v.vertex)));
            o.viewDir = normalize(mul(rotation, ObjSpaceViewDir(v.vertex)));
#endif

        return o;
    }

    fixed4 frag (v2f i) : SV_Target
    {
        float4 _Col = UNITY_ACCESS_INSTANCED_PROP(_Color_arr, _Color);
        fixed4 tex = tex2D(_MainTex, i.uv);
        fixed4 col = tex * _Col;

#ifdef _LIGHTING_REAL
            half3 halfDir = normalize(i.lightDir + i.viewDir);
            half3 normal = UnpackNormal(tex2D(_BumpMap, i.uv));
            half4 diff = saturate(dot(normal, i.lightDir)) * _LightColor0;
            half3 spec = pow(max(0, dot(normal, halfDir)), _Shininess * 128.0) * _LightColor0.rgb * tex.rgb;
            col.rgb = col.rgb * diff + spec;
#endif

        // apply fog
        UNITY_APPLY_FOG(i.fogCoord, col);

        return col;
    }

    fixed4 frag_shadow(v2f i) : SV_Target {
        return (fixed4)0;
    }
    ENDCG

    SubShader 
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog
            #pragma multi_compile_instancing
            #pragma target 4.5
            #pragma shader_feature _LIGHTING_UNLIT _LIGHTING_REAL

            ENDCG
        }

    }

}
