Shader "AnimationGpuInstancing/Base_Shadow"
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
    #pragma shader_feature_local _AUDIOLINK

    #include "Includes/AnimationGpuInstancing_Common.cginc"

    UNITY_INSTANCING_BUFFER_START(Props2)
    UNITY_DEFINE_INSTANCED_PROP(fixed4, _Color)
    #define _Color_arr Props2
    UNITY_INSTANCING_BUFFER_END(Props2)

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

    sampler2D _MainTex;
    float4 _MainTex_ST;
    
    sampler2D _BumpMap;

    half _Shininess;
    float4 _LightColor0;

    v2f vert (appdata_AGI v)
    {
        v2f o;

        UNITY_SETUP_INSTANCE_ID(v);
        UNITY_TRANSFER_INSTANCE_ID(v, o);
        
        CalculateAGI(v);

        o.vertex = UnityObjectToClipPos(v.vertex);
        UNITY_TRANSFER_FOG(o,o.vertex);
        o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
        o.normal = float4(v.normal, 0);

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
        
        Pass
                {
                    Name "ShadowCaster"
                    Tags{"LightMode" = "ShadowCaster"}
                    Zwrite On
                    ZTest LEqual

                    CGPROGRAM
                    #pragma vertex vert
                    #pragma fragment frag _shadow
                    #pragma multi_compile_shadowcaster
                    #pragma multi_compile_instancing
                    #pragma target 4.5
                

                    ENDCG

                }

    }

}




