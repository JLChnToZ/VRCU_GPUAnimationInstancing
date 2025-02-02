﻿using UnityEngine;
using System.Collections;
using System.Collections.Generic;
using System.Linq;
using UnityEditor;


public class AGI_ShaderInspector : ShaderGUI
{
    #region MaterialProperties 
    MaterialProperty mainTex;
    MaterialProperty color;
    MaterialProperty animTex;
    MaterialProperty startFrame;
    MaterialProperty frameCount;
    MaterialProperty offsetSeconds;
    MaterialProperty pixelsPerFrame;

    MaterialProperty isRootMotion;
    MaterialProperty repeatTex;
    MaterialProperty repeatStartFrame;
    MaterialProperty repeatMax;
    MaterialProperty repeatNum;

    MaterialProperty baseSpeed;
    MaterialProperty timeNoise;

    MaterialProperty audioLink;
    MaterialProperty alChronoIndex;
    MaterialProperty alBand;
    MaterialProperty alSpeed;

    MaterialProperty isPause;
    MaterialProperty isLighting;
    MaterialProperty shininess;
    MaterialProperty bumpMap;
    MaterialProperty instancing;

    #endregion


    public override void OnGUI(MaterialEditor materialEditor, MaterialProperty[] props)
    {
    
        
        Material material = materialEditor.target as Material;

        /* *** *** *** */

        mainTex = FindProperty("_MainTex", props);
        color = FindProperty("_Color", props);
        animTex = FindProperty("_AnimTex", props);
        startFrame = FindProperty("_StartFrame", props);
        frameCount = FindProperty("_FrameCount", props);
        offsetSeconds = FindProperty("_OffsetSeconds", props);
        pixelsPerFrame = FindProperty("_PixelsPerFrame", props);

        isRootMotion = FindProperty("_ROOT_MOTION", props);
        repeatTex = FindProperty("_RepeatTex", props);
        repeatStartFrame = FindProperty("_RepeatStartFrame", props);
        repeatMax = FindProperty("_RepeatMax", props);
        repeatNum = FindProperty("_RepeatNum", props);

        baseSpeed = FindProperty("_BaseSpeed", props);
        timeNoise = FindProperty("_TimeNoise", props);

        audioLink = FindProperty("_AUDIOLINK", props);
        alChronoIndex = FindProperty("_AudioLinkChronotensityIndex", props);
        alBand = FindProperty("_AudioLinkBand", props);
        alSpeed = FindProperty("_AudioLinkSpeed", props);

        isLighting = FindProperty("_LIGHTING", props);
        shininess = FindProperty("_Shininess", props);
        bumpMap = FindProperty("_BumpMap", props);

        instancing = FindProperty("_INSTANCING", props);
        /* *** *** *** */

        // materialEditor.ShaderProperty(mainTexProps, mainTexProps.displayName);
        materialEditor.TexturePropertySingleLine(new GUIContent("Main Texture"), mainTex, color);
        using (new EditorGUI.IndentLevelScope())
        {
            materialEditor.TextureScaleOffsetProperty(mainTex);
            EditorGUILayout.Space();
        }

        EditorGUILayout.Space();


        /* *** Animation *** */
        materialEditor.TexturePropertySingleLine(new GUIContent("Animation Texture"), animTex);

        EditorGUI.indentLevel++;

        materialEditor.ShaderProperty(startFrame, startFrame.displayName);
        materialEditor.ShaderProperty(frameCount, frameCount.displayName);
        materialEditor.ShaderProperty(offsetSeconds, offsetSeconds.displayName);
        materialEditor.ShaderProperty(pixelsPerFrame, pixelsPerFrame.displayName);

        EditorGUI.indentLevel--;

        EditorGUILayout.Space();

        /* *** Repeat *** */
        materialEditor.ShaderProperty(isRootMotion, isRootMotion.displayName);

        EditorGUI.indentLevel++;
        if (isRootMotion.floatValue == 1f) {
            materialEditor.TexturePropertySingleLine(new GUIContent("Repeat Texture"), repeatTex);
            materialEditor.ShaderProperty(repeatStartFrame, repeatStartFrame.displayName);
            materialEditor.ShaderProperty(repeatMax, repeatMax.displayName);
            materialEditor.ShaderProperty(repeatNum, repeatNum.displayName);
        }
        EditorGUI.indentLevel--;

        EditorGUILayout.Space();

        /* *** Speed *** */
        materialEditor.ShaderProperty(baseSpeed, baseSpeed.displayName);
        materialEditor.ShaderProperty(timeNoise, timeNoise.displayName);

        EditorGUILayout.Space();

        /* *** AudioLink *** */
        materialEditor.ShaderProperty(audioLink, audioLink.displayName);

        EditorGUI.indentLevel++;
        if (audioLink.floatValue == 1F)
        {
            materialEditor.ShaderProperty(alChronoIndex, alChronoIndex.displayName);
            materialEditor.ShaderProperty(alBand, alBand.displayName);
            materialEditor.ShaderProperty(alSpeed, alSpeed.displayName);
        }
        EditorGUI.indentLevel--;

        EditorGUILayout.Space();

        /* *** Lighting *** */

        materialEditor.ShaderProperty(isLighting, isLighting.displayName);
        EditorGUI.indentLevel++;
        if (isLighting.floatValue == 1f)
        {
            materialEditor.TexturePropertySingleLine(new GUIContent("Normal Map"), bumpMap);
            using (new EditorGUI.IndentLevelScope())
            {
                materialEditor.TextureScaleOffsetProperty(bumpMap);
                EditorGUILayout.Space();
            }

        }
        EditorGUI.indentLevel--;
        EditorGUILayout.Space();

        /* *** GPU Instancing *** */
        materialEditor.ShaderProperty(instancing, "Enable GPU Instancing");
        if (instancing.floatValue == 1f) material.enableInstancing = true;
        else material.enableInstancing = false;




    }
}

enum AudioLinkChronotensityType
{
    MotionAsIntensity,
    MotionAsIntensityFiltered,
    MotionBackAndForth,
    MotionBackAndForthFiltered,
    SpeedUpOnDark,
    SpeedUpOnDarkFiltered,
    SpeedUpOnDarkSlowDownOnLight,
    SpeedUpOnDarkSlowDownOnLightFiltered,
}
