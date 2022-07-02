#if !defined(OPENLIT_COMMON_INCLUDED)
#define OPENLIT_COMMON_INCLUDED

sampler2D _MainTex;
float4  _MainTex_ST;
float   _ShadowThreshold;
uint    _ReceiveShadow;

// [OpenLit] Properties for lighting
float   _AsUnlit;
float   _VertexLightStrength;
float   _LightMinLimit;
float   _LightMaxLimit;
float   _BeforeExposureLimit;
float   _MonochromeLighting;
float   _AlphaBoostFA;
float4  _LightDirectionOverride;
#endif