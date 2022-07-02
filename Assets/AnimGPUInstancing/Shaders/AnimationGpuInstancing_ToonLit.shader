// Based on OpenLit Sample (CC0)
Shader "AnimationGpuInstancing/ToonLit"
{
    Properties
    {
        //------------------------------------------------------------------------------------------------------------------------------
        // Properties for material
        _MainTex ("Texture", 2D) = "white" {}
        _ShadowThreshold ("Shadow Threshold", Range(-1,1)) = 0
        [Toggle(_)] _ReceiveShadow ("Receive Shadow", Int) = 0
        [Toggle(_PACK_LIGHTDATAS)] _PackLightDatas ("[Debug] Pack Light Datas", Int) = 0

        //------------------------------------------------------------------------------------------------------------------------------
        // AGI Specific Properties
        [Space]
        [NoScaleOffset] _AnimTex("Animation Texture", 2D) = "white" {}

        _StartFrame("Start Frame", Float) = 0 
        _FrameCount("Frame Count", Float) = 1 
        _OffsetSeconds("Offset Seconds", Float) = 0 
        _PixelsPerFrame("Pixels Per Frame", Float) = 0 

        [Space]
        [Toggle] _ROOT_MOTION("Apply Root Motion", Float) = 0
        [NoScaleOffset]_RepeatTex("Repeat Texture", 2D) = "white" {}
        _RepeatStartFrame("Repeat Start Frame", Float) = 0
        _RepeatMax("Repeat Max", FLoat) = 1
        _RepeatNum ("Repeat Num", Float) = 1
    
        [Space]
        _BaseSpeed ("Base Speed", Float) = 1
        _TimeNoise ("Position Based Timing Noise", Float) = 0

        [Space]
        [Toggle(_AUDIOLINK)] _AUDIOLINK("AudioLink", Int) = 0
        [Enum(AudioLinkChronotensityType)] _AudioLinkChronotensityIndex ("AudioLink Chronotensity Mode", Int) = 0
        [Enum(None, 0, Bass, 1, Low Mid, 2, High Mid, 3, Treble, 4)]
        _AudioLinkBand ("AudioLink Band", Int) = 0
        _AudioLinkSpeed ("AudioLink Speed", Float) = 1

        [Toggle] _INSTANCING("Gpu Instancing", Float) = 1

        //------------------------------------------------------------------------------------------------------------------------------
        // [OpenLit] Properties for lighting

        // It is more accurate to set _LightMinLimit to 0, but the avatar will be black.
        // In many cases, setting a small value will give better results.

        // _VertexLightStrength should be set to 1, but vertex lights will not work properly if there are multiple SkinnedMeshRenderers.
        // And many users seem to prefer to use multiple SkinnedMeshRenderers.
        [Space]
        _AsUnlit                ("As Unlit", Range(0,1)) = 0
        _VertexLightStrength    ("Vertex Light Strength", Range(0,1)) = 0
        _LightMinLimit          ("Light Min Limit", Range(0,1)) = 0.05
        _LightMaxLimit          ("Light Max Limit", Range(0,10)) = 1
        _BeforeExposureLimit    ("Before Exposure Limit", Float) = 10000
        _MonochromeLighting     ("Monochrome lighting", Range(0,1)) = 0
        _AlphaBoostFA           ("Boost Transparency in ForwardAdd", Range(1,100)) = 10
        _LightDirectionOverride ("Light Direction Override", Vector) = (0.001,0.002,0.001,0)

        // Based on Semantic Versioning 2.0.0
        // https://semver.org/spec/v2.0.0.html
        [HideInInspector] _OpenLitVersionMAJOR ("MAJOR", Int) = 1
        [HideInInspector] _OpenLitVersionMINOR ("MINOR", Int) = 0
        [HideInInspector] _OpenLitVersionPATCH ("PATCH", Int) = 1

        //------------------------------------------------------------------------------------------------------------------------------
        // [OpenLit] ForwardBase
        [Enum(UnityEngine.Rendering.BlendMode)] _SrcBlend   ("SrcBlend", Int) = 1
        [Enum(UnityEngine.Rendering.BlendMode)] _DstBlend   ("DstBlend", Int) = 0
        [Enum(UnityEngine.Rendering.BlendOp)]   _BlendOp    ("BlendOp", Int) = 0

        //------------------------------------------------------------------------------------------------------------------------------
        // [OpenLit] ForwardAdd uses "BlendOp Max" to avoid overexposure
        // This blending causes problems with transparent materials, so use the _AlphaBoostFA property to boost transparency.
        [Enum(UnityEngine.Rendering.BlendMode)] _SrcBlendFA ("ForwardAdd SrcBlend", Int) = 1
        [Enum(UnityEngine.Rendering.BlendMode)] _DstBlendFA ("ForwardAdd DstBlend", Int) = 1
        [Enum(UnityEngine.Rendering.BlendOp)]   _BlendOpFA  ("ForwardAdd BlendOp", Int) = 4
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }

        Pass
        {
            Tags {"LightMode" = "ForwardBase"}

            BlendOp [_BlendOp], Add
            Blend [_SrcBlend] [_DstBlend], One OneMinusSrcAlpha

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fwdbase
            #pragma multi_compile_fog
            #pragma shader_feature_local _ _PACK_LIGHTDATAS
            #pragma shader_feature_local _ _AUDIOLINK
            #if defined(SHADER_API_GLES)
                #undef _PACK_LIGHTDATAS
            #endif

            #include "UnityCG.cginc"
            #include "Lighting.cginc"
            #include "AutoLight.cginc"

            // [OpenLit] Include this
            #include "Includes/OpenLit/common.hlsl"
            #include "Includes/OpenLit/core.hlsl"

            #include "Includes/AnimationGpuInstancing_Common.cginc"

            struct v2f
            {
                float4 pos          : SV_POSITION;
                float3 positionWS   : TEXCOORD0;
                float2 uv           : TEXCOORD1;
                float3 normalWS     : TEXCOORD2;
                // [OpenLit] Add light datas
                #if defined(_PACK_LIGHTDATAS)
                    nointerpolation uint3 lightDatas : TEXCOORD3;
                    UNITY_FOG_COORDS(4)
                    UNITY_LIGHTING_COORDS(5, 6)
                    #if !defined(LIGHTMAP_ON) && UNITY_SHOULD_SAMPLE_SH
                        float3 vertexLight  : TEXCOORD7;
                    #endif
                #else
                    nointerpolation float3 lightDirection : TEXCOORD3;
                    nointerpolation float3 directLight : TEXCOORD4;
                    nointerpolation float3 indirectLight : TEXCOORD5;
                    UNITY_FOG_COORDS(6)
                    UNITY_LIGHTING_COORDS(7, 8)
                    #if !defined(LIGHTMAP_ON) && UNITY_SHOULD_SAMPLE_SH
                        float3 vertexLight  : TEXCOORD9;
                    #endif
                #endif
                UNITY_VERTEX_OUTPUT_STEREO
            };

            v2f vert(appdata_AGI v)
            {
                v2f o;
                UNITY_INITIALIZE_OUTPUT(v2f,o);
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

                CalculateAGI(v);

                o.positionWS    = mul(unity_ObjectToWorld, float4(v.vertex.xyz, 1.0));
                o.pos           = UnityWorldToClipPos(o.positionWS);
                o.uv            = TRANSFORM_TEX(v.texcoord, _MainTex);
                o.normalWS      = UnityObjectToWorldNormal(v.normal);
                UNITY_TRANSFER_FOG(o,o.pos);
                UNITY_TRANSFER_LIGHTING(o,v.texcoord1);

                // [OpenLit] Calculate and copy vertex lighting
                #if !defined(LIGHTMAP_ON) && UNITY_SHOULD_SAMPLE_SH && defined(VERTEXLIGHT_ON)
                    o.vertexLight = ComputeAdditionalLights(o.positionWS, o.pos) * _VertexLightStrength;
                    o.vertexLight = min(o.vertexLight, _LightMaxLimit);
                #endif

                // [OpenLit] Calculate and copy light datas
                OpenLitLightDatas lightDatas;
                ComputeLights(lightDatas, _LightDirectionOverride);
                CorrectLights(lightDatas, _LightMinLimit, _LightMaxLimit, _MonochromeLighting, _AsUnlit);
                #if defined(_PACK_LIGHTDATAS)
                    PackLightDatas(o.lightDatas, lightDatas);
                #else
                    o.lightDirection    = lightDatas.lightDirection;
                    o.directLight       = lightDatas.directLight;
                    o.indirectLight     = lightDatas.indirectLight;
                #endif

                return o;
            }

            half4 frag(v2f i) : SV_Target
            {
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i);
                UNITY_LIGHT_ATTENUATION(attenuation, i, i.positionWS);

                // [OpenLit] Copy light datas from the input
                OpenLitLightDatas lightDatas;
                #if defined(_PACK_LIGHTDATAS)
                    UnpackLightDatas(lightDatas, i.lightDatas);
                #else
                    lightDatas.lightDirection   = i.lightDirection;
                    lightDatas.directLight      = i.directLight;
                    lightDatas.indirectLight    = i.indirectLight;
                #endif

                float3 N = normalize(i.normalWS);
                float3 L = lightDatas.lightDirection;
                float NdotL = dot(N,L);
                float factor = NdotL > _ShadowThreshold ? 1 : 0;
                if(_ReceiveShadow) factor *= attenuation;

                half4 col = tex2D(_MainTex, i.uv);
                half3 albedo = col.rgb;
                col.rgb *= lerp(lightDatas.indirectLight, lightDatas.directLight, factor);
                #if !defined(LIGHTMAP_ON) && UNITY_SHOULD_SAMPLE_SH
                    col.rgb += albedo.rgb * i.vertexLight;
                    col.rgb = min(col.rgb, albedo.rgb * _LightMaxLimit);
                #endif
                UNITY_APPLY_FOG(i.fogCoord, col);
                return col;
            }
            ENDHLSL
        }

        Pass
        {
            Tags {"LightMode" = "ForwardAdd"}

            // [OpenLit] ForwardAdd uses "BlendOp Max" to avoid overexposure
            BlendOp [_BlendOpFA], Add
            Blend [_SrcBlendFA] [_DstBlendFA], Zero One

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fwdadd
            #pragma multi_compile_fog
            #pragma shader_feature_local _ _AUDIOLINK

            #include "UnityCG.cginc"
            #include "Lighting.cginc"
            #include "AutoLight.cginc"

            #include "Includes/OpenLit/common.hlsl"
            #include "Includes/OpenLit/core.hlsl"

            #include "Includes/AnimationGpuInstancing_Common.cginc"

            struct v2f
            {
                float4 pos          : SV_POSITION;
                float3 positionWS   : TEXCOORD0;
                float2 uv           : TEXCOORD1;
                float3 normalWS     : TEXCOORD2;
                UNITY_FOG_COORDS(3)
                UNITY_LIGHTING_COORDS(4, 5)
                UNITY_VERTEX_OUTPUT_STEREO
            };

            v2f vert(appdata_AGI v)
            {
                v2f o;
                UNITY_INITIALIZE_OUTPUT(v2f,o);
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

                CalculateAGI(v);

                o.positionWS    = mul(unity_ObjectToWorld, float4(v.vertex.xyz, 1.0));
                o.pos           = UnityWorldToClipPos(o.positionWS);
                o.uv            = TRANSFORM_TEX(v.texcoord, _MainTex);
                o.normalWS      = UnityObjectToWorldNormal(v.normal);
                UNITY_TRANSFER_FOG(o,o.pos);
                UNITY_TRANSFER_LIGHTING(o,v.texcoord1);
                return o;
            }

            half4 frag(v2f i) : SV_Target
            {
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i);
                UNITY_LIGHT_ATTENUATION(attenuation, i, i.positionWS);
                float3 N = normalize(i.normalWS);
                float3 L = normalize(UnityWorldSpaceLightDir(i.positionWS));
                float NdotL = dot(N,L);
                float factor = NdotL > _ShadowThreshold ? 1 : 0;

                half4 col = tex2D(_MainTex, i.uv);
                col.rgb *= lerp(0.0, OPENLIT_LIGHT_COLOR, factor * attenuation);
                UNITY_APPLY_FOG(i.fogCoord, col);

                // [OpenLit] Premultiply (only for transparent materials)
                col.rgb *= saturate(col.a * _AlphaBoostFA);

                return col;
            }
            ENDHLSL
        }
        Pass
        {
            Name "ShadowCaster"
            Tags { "LightMode" = "ShadowCaster" }

            ZWrite On ZTest LEqual

            CGPROGRAM
            #pragma target 3.0
            #pragma shader_feature_local _ _ALPHATEST_ON _ALPHABLEND_ON _ALPHAPREMULTIPLY_ON
            #pragma shader_feature_local _METALLICGLOSSMAP
            #pragma shader_feature_local _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A
            #pragma shader_feature_local _PARALLAXMAP
            #pragma shader_feature_local _ _AUDIOLINK
            #pragma multi_compile_shadowcaster
            #pragma multi_compile_instancing
            #pragma vertex vert
            #pragma fragment fragShadowCaster

            #include "Includes/AnimationGpuInstancing_Common.cginc"
            #include "UnityStandardShadow.cginc"

            // Copied from UnityStandardShadow.cginc but with extra AGI vertex flow added.
            void vert(appdata_AGI v
                , out float4 opos : SV_POSITION
                #ifdef UNITY_STANDARD_USE_SHADOW_OUTPUT_STRUCT
                , out VertexOutputShadowCaster o
                #endif
                #ifdef UNITY_STANDARD_USE_STEREO_SHADOW_OUTPUT_STRUCT
                , out VertexOutputStereoShadowCaster os
                #endif
            )
            {
                UNITY_SETUP_INSTANCE_ID(v);
                CalculateAGI(v);
                #ifdef UNITY_STANDARD_USE_STEREO_SHADOW_OUTPUT_STRUCT
                    UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(os);
                #endif
                TRANSFER_SHADOW_CASTER_NOPOS(o,opos)
                #if defined(UNITY_STANDARD_USE_SHADOW_UVS)
                    o.tex = TRANSFORM_TEX(v.texcoord, _MainTex);

                    #ifdef _PARALLAXMAP
                        TANGENT_SPACE_ROTATION;
                        o.viewDirForParallax = mul (rotation, ObjSpaceViewDir(v.vertex));
                    #endif
                #endif
            }
            ENDCG
        }
        Pass
        {
            Name "ShadowCaster"
            Tags { "LightMode" = "ShadowCaster" }

            ZWrite On ZTest LEqual

            CGPROGRAM
            #pragma target 2.0

            #pragma shader_feature_local _ _ALPHATEST_ON _ALPHABLEND_ON _ALPHAPREMULTIPLY_ON
            #pragma shader_feature_local _METALLICGLOSSMAP
            #pragma shader_feature_local _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A
            #pragma skip_variants SHADOWS_SOFT
            #pragma multi_compile_shadowcaster

            #pragma vertex vert
            #pragma fragment fragShadowCaster

            #include "Includes/AnimationGpuInstancing_Common.cginc"
            #include "UnityStandardShadow.cginc"

            // Copied from UnityStandardShadow.cginc but with extra AGI vertex flow added.
            void vert(appdata_AGI v
                , out float4 opos : SV_POSITION
                #ifdef UNITY_STANDARD_USE_SHADOW_OUTPUT_STRUCT
                , out VertexOutputShadowCaster o
                #endif
                #ifdef UNITY_STANDARD_USE_STEREO_SHADOW_OUTPUT_STRUCT
                , out VertexOutputStereoShadowCaster os
                #endif
            )
            {
                UNITY_SETUP_INSTANCE_ID(v);
                CalculateAGI(v);
                #ifdef UNITY_STANDARD_USE_STEREO_SHADOW_OUTPUT_STRUCT
                    UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(os);
                #endif
                TRANSFER_SHADOW_CASTER_NOPOS(o,opos)
                #if defined(UNITY_STANDARD_USE_SHADOW_UVS)
                    o.tex = TRANSFORM_TEX(v.texcoord, _MainTex);

                    #ifdef _PARALLAXMAP
                        TANGENT_SPACE_ROTATION;
                        o.viewDirForParallax = mul (rotation, ObjSpaceViewDir(v.vertex));
                    #endif
                #endif
            }
            ENDCG
        }
    }
    Fallback "Standard"
}
