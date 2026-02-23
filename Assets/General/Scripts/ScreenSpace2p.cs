using System;
using System.Collections.Generic;
using UnityEngine;

// [ExecuteInEditMode]
public class ImageEffect : MonoBehaviour
{
    public AudioSource audioSource;

    public Material material;
    public List<Material> materials;
    int materialIndex = 0;

    private RenderTexture rt1;

    // --- Scene start times as readonly constants ---
    //public static class SceneStartTimes
    //{
    //    public static float scene1Start = 46.8f; // intro start
    //    public static float scene2Start = 75.0f; // jolly
    //    public static float scene3Start = 99.75f; // soft
    //    public static float scene4Start = 134.7f; // superjolly
    //    public static float scene5Start = 162.5f; // spinny
    //    public static float scene6Start = 200.0f; // final / extra
    //}

    void Update()
    {
        //float t = audioSource.time;
        //float localT = t;
        //float bpm = 58.0f;
        //float offset = 0.6f;

        //if (t < SceneStartTimes.scene2Start) // intro
        //{
        //    materialIndex = 0;
        //    localT = t - SceneStartTimes.scene1Start;
        //    offset = 0.4f;
        //}
        //else if (t < SceneStartTimes.scene3Start) // jolly
        //{
        //    materialIndex = 1;
        //    localT = t - SceneStartTimes.scene2Start;
        //    offset = 0.0f;
        //}
        //else if (t < SceneStartTimes.scene4Start) // soft
        //{
        //    materialIndex = 2;
        //    localT = t - SceneStartTimes.scene3Start;
        //}
        //else if (t < SceneStartTimes.scene5Start) // superjolly
        //{
        //    materialIndex = 3;
        //    localT = t - SceneStartTimes.scene4Start;
        //    bpm = 72.0f;
        //    offset = 0.2f;
        //}
        //else if (t < SceneStartTimes.scene6Start) // spinny
        //{
        //    materialIndex = 4;
        //    localT = t - SceneStartTimes.scene5Start;
        //}
        //else
        //{
        //    materialIndex = 5;
        //    localT = t - SceneStartTimes.scene6Start;
        //    bpm = 90.0f;
        //}

        // Debug.Log(localT);

        material = materials[materialIndex];

        //Shader.SetGlobalFloat("_time", localT);

        //// Beat calculation
        //float secPerBeat = 60.0f / bpm;
        //float beat = localT / secPerBeat + offset; // int + frac
        //int intBeat = (int)Mathf.Floor(beat);
        //float fracBeat = beat - intBeat;

        //Shader.SetGlobalInt("_intBeat", intBeat);
        //Shader.SetGlobalFloat("_fracBeat", fracBeat);
    }

    void Start()
    {
        // Application.targetFrameRate = 60;
    }

    void OnEnable()
    {
        rt1 = new RenderTexture(Screen.width, Screen.height, 0, RenderTextureFormat.ARGB32);
        rt1.Create();
    }

    void OnRenderImage(RenderTexture source, RenderTexture destination)
    {
        if (material == null) return;

        Graphics.Blit(source, rt1, material, 0);
        Graphics.Blit(rt1, destination, material, 1);
    }

    void OnDisable()
    {
        if (rt1 != null) rt1.Release();
    }
}
