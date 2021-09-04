﻿
using UdonSharp;
using UnityEngine;
using VRC.SDKBase;
using VRC.Udon;


public class LogicController : UdonSharpBehaviour
{
    [SerializeField] int NumSpawn;
    public GameObject pfb;
    private GameObject[] myList = new GameObject[10];

    void Start()
    {

        for (int i = 0; i < NumSpawn; ++i)
        {
            myList[i] = VRCInstantiate(pfb);
            myList[i].transform.position = new Vector3(i * 2.0f, 0.0f, 0.0f);
            // SendCustomEventDelayedSeconds(nameof(Spawn), 0.5f);
        }

    }
    public void Spawn()
    {
        //GameObject go = VRCInstantiate(pfb);
        //float posX = Random.Range(-15.0f, 15.0f);
        //float posZ = Random.Range(-15.0f, 15.0f);
        //go.transform.position = new Vector3(posX, 0.0f, posZ);


        //var idx = Random.Range(0, 1);
        //var frameInformation = FrameInformations[idx];

        //MaterialPropertyBlock props = new MaterialPropertyBlock();
        //// props.SetColor("_Color", new Color(Random.Range(0.0f, 1.0f), Random.Range(0.0f, 1.0f), Random.Range(0.0f, 1.0f)));
        //props.SetFloat("_OffsetSeconds", Random.Range(0.0f, 10.0f));
        //props.SetFloat("_StartFrame", frameInformation.StartFrame);
        //props.SetFloat("_EndFrame", frameInformation.EndFrame);
        //props.SetFloat("_FrameCount", frameInformation.FrameCount);

        //MeshRenderer meshRenderer = bear.GetComponent<MeshRenderer>();
        //meshRenderer.SetPropertyBlock(props);
    }
}
