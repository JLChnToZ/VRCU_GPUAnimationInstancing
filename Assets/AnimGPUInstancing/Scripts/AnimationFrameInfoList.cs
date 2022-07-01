
using UdonSharp;
using UnityEngine;

#if UDON
using VRC.SDKBase;
using VRC.Udon;

public class AnimationFrameInfoList : UdonSharpBehaviour
#else
public class AnimationFrameInfoList : MonoBehaviour
#endif
{

    public Vector4[] FrameInfo;

}
