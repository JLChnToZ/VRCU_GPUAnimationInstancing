// Based on OpenLit Sample (CC0)
Shader "Hidden/AnimationGpuInstancing/ToonLit"
{
    SubShader
    {
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

            #include "AnimationGpuInstancing_Common.cginc"
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
}