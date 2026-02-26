using System;
using UnityEngine;

public class MouseMove : MonoBehaviour
{

    private Vector3 cameraPosition = new Vector3(0.0f, 1.5f, 10.0f);
    private Vector2 cameraRotation = Vector2.zero;
    private float cameraDistance = 3f;

    private Vector3 targetPosition = Vector3.zero;
    private bool isDragging = false;
    private Vector2 lastMousePosition;

    //void Start()
    //{
    //    cameraPosition = new Vector3(0, 1.5f, 3f);
    //    targetPosition = Vector3.zero;
    //    UpdateShaderUniforms();
    //}

    void Start()
    {
        cameraPosition = new Vector3(0, 1.5f, 5f);
        targetPosition = Vector3.zero;

        
        Vector3 directionToTarget = targetPosition - cameraPosition;
        cameraDistance = directionToTarget.magnitude;

        Vector3 normalizedDirection = directionToTarget.normalized;
        cameraRotation.y = Mathf.Atan2(normalizedDirection.x, normalizedDirection.z) * Mathf.Rad2Deg;
        cameraRotation.x = Mathf.Asin(normalizedDirection.y) * Mathf.Rad2Deg;

        UpdateShaderUniforms();
    }


    void Update()
    {
        HandleInput();
        UpdateShaderUniforms();

        if (Input.GetKeyDown(KeyCode.Space))
        {
            Debug.Log("Cam:" + cameraPosition);
            Debug.Log("Target:" + targetPosition);
        }
    }

    void HandleInput()
    {
        // Mouse drag for rotation
        if (Input.GetMouseButtonDown(0))
        {
            isDragging = true;
            lastMousePosition = Input.mousePosition;
        }

        if (Input.GetMouseButtonUp(0))
        {
            isDragging = false;
        }

        if (isDragging && Input.GetMouseButton(0))
        {
            Vector2 currentMousePosition = Input.mousePosition;
            Vector2 delta = (currentMousePosition - lastMousePosition) * 0.1f;

            cameraRotation.x += delta.y; // Pitch
            cameraRotation.y += delta.x; // Yaw

            // Clamp pitch to avoid flipping
            cameraRotation.x = Mathf.Clamp(cameraRotation.x, -89f, 89f);

            lastMousePosition = currentMousePosition;
        }

        // Scroll wheel for zoom
        float scroll = Input.GetAxis("Mouse ScrollWheel");
        if (Mathf.Abs(scroll) > 0.001f)
        {
            cameraDistance = Mathf.Clamp(cameraDistance - scroll * 2f, 0.5f, 20f);
        }

        if (Input.GetKeyDown(KeyCode.R))
        {
            cameraPosition = new Vector3(0, 1.5f, 3f);
            cameraRotation = Vector2.zero;
            cameraDistance = 3f;
            targetPosition = Vector3.zero;
        }

        // Update camera position based on rotation and distance
        UpdateCameraPosition();
    }

    void UpdateCameraPosition()
    {
        // Convert to spherical coordinates
        float theta = cameraRotation.y * Mathf.Deg2Rad; // Yaw
        float phi = cameraRotation.x * Mathf.Deg2Rad;   // Pitch

        Vector3 direction = new Vector3(
            Mathf.Sin(theta) * Mathf.Cos(phi),
            Mathf.Sin(phi),
            Mathf.Cos(theta) * Mathf.Cos(phi)
        );

        cameraPosition = targetPosition - direction * cameraDistance;
    }

    void UpdateShaderUniforms()
    {
        // print 
        // Debug.Log("Camera Position: " + cameraPosition + " Target Position: " + targetPosition);
        Shader.SetGlobalVector("_CameraPos", cameraPosition);
        Shader.SetGlobalVector("_CameraTarget", targetPosition);
        Shader.SetGlobalFloat("_time", Time.time);
    }
}