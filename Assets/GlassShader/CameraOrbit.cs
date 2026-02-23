using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class CameraOrbit : MonoBehaviour
{
    public float rotationSpeed = 0.01f;
    public Vector3 target = Vector3.zero;
    public float radius = 10f;

    private float angle = 0f;

    void Update()
    {
        angle -= rotationSpeed * Time.deltaTime * 20;

        float x = Mathf.Cos(angle) * radius;
        float z = Mathf.Sin(angle) * radius;
        float y = transform.position.y; 

        transform.position = new Vector3(x, y, z);

        transform.LookAt(target);
    }
}
