using System;
using System.Collections.Generic;
using UnityEngine;
[ExecuteInEditMode]
public class ScreenSpace : MonoBehaviour
{
    public Material mat;


    void Update()
    {
        //Shader.SetGlobalFloat("_time", localT);

    }

    void Start()
    {
        // Application.targetFrameRate = 60;
    }

    void OnRenderImage(RenderTexture source, RenderTexture destination)
    {
        if (mat == null) return;

        Graphics.Blit(source, destination, mat);
    }
}

    
