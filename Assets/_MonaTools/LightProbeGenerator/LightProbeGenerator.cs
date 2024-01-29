#if UNITY_EDITOR
using System.Collections.Generic;
using System.Linq;
using UnityEngine;
using UnityEngine.AI;

namespace Mona
{
    [ExecuteInEditMode]
    public class LightProbeGenerator : MonoBehaviour
    {
        private LightProbeGroup lightProbeGroup;
        private List<Vector3> lightProbePositions = new List<Vector3>();


        public bool useNavMeshPlacement = true;
        public bool useObjectBoundsPlacement = false;
        public bool useVolumeScatterPlacement = true;
        public bool useRayCastPlacement = true;
        public int generationResolution = 8;
        public Vector3 bBoxCenter = new Vector3(0,0,0);
        public Vector3 bBoxSize = new Vector3(50,50,50);
        public int mergeDistance = 2;

        public void Generate()
        {
            DestroyImmediate(this.gameObject.GetComponent<LightProbeGroup>());
            lightProbeGroup = this.gameObject.AddComponent<LightProbeGroup>();

            lightProbePositions = new List<Vector3>();

            if (useNavMeshPlacement) { NavMeshPlacement(); }

            if (useObjectBoundsPlacement) { ObjectBoundsPlacement(); }

            if (useVolumeScatterPlacement) { VolumeScatterPlacement(); }

            if (useRayCastPlacement) { RayCastPlacement(); }

            RemoveInvalidProbes();

            Debug.Log($"LightProbe's Placed:{lightProbePositions.Count}");

            lightProbeGroup.probePositions = lightProbePositions.ToArray();
        }

        public void OptimizeProbes()
        {
            lightProbeGroup = this.gameObject.GetComponent<LightProbeGroup>();
            lightProbePositions = lightProbeGroup.probePositions.ToList<Vector3>();
            int startCount = 0;
            
            while (startCount != lightProbePositions.Count)
            {
                startCount = lightProbePositions.Count;
                for (int j = 0; j < lightProbePositions.Count; j++)
                {
                    for (int i = 0; i < lightProbePositions.Count; i++)
                    {
                        if (j == i) {continue;}
                        if (Vector3.Distance(lightProbePositions[j], lightProbePositions[i]) < mergeDistance)
                        {
                            Vector3 p = Vector3.Lerp(lightProbePositions[j], lightProbePositions[i], 0.5f);
                            if (i > j)
                            {
                                lightProbePositions.RemoveAt(i);
                                lightProbePositions.RemoveAt(j);
                            }
                            else
                            {
                                lightProbePositions.RemoveAt(j);
                                lightProbePositions.RemoveAt(i);
                            }
                            lightProbePositions.Append<Vector3>(p);
                            break;
                        }
                    }
                }
            }

            RemoveInvalidProbes();

            Debug.Log($"Optimized LightProbe Count:{lightProbePositions.Count}");

            lightProbeGroup.probePositions = lightProbePositions.ToArray();
        }
        
        private void NavMeshPlacement()
        {
            NavMeshBuildSettings navMeshBuildSettings = new NavMeshBuildSettings();
                
            navMeshBuildSettings.agentRadius = 0.5f;
            navMeshBuildSettings.agentHeight = 2f;
            navMeshBuildSettings.agentSlope = 45f;
            navMeshBuildSettings.agentClimb = 0.4f;

            List<NavMeshBuildSource> navMeshBuildSources = new List<NavMeshBuildSource>();
            List<NavMeshBuildMarkup> navMeshBuildMarkups = new List<NavMeshBuildMarkup>();
            NavMeshBuildMarkup navMeshBuildMarkup = new NavMeshBuildMarkup();
            navMeshBuildMarkup.root = null;
            navMeshBuildMarkup.area = 0;
            navMeshBuildMarkup.overrideArea = true;

            NavMeshBuilder.CollectSources(GameObject.FindWithTag("Space").transform, 1, NavMeshCollectGeometry.RenderMeshes, 31, navMeshBuildMarkups, navMeshBuildSources);
            NavMeshData navMeshData = NavMeshBuilder.BuildNavMeshData(navMeshBuildSettings, navMeshBuildSources, new Bounds(this.gameObject.transform.position, new Vector3(1000f,1000f,1000f)), this.gameObject.transform.position, this.gameObject.transform.rotation);

            NavMesh.AddNavMeshData(navMeshData);

            NavMeshTriangulation navMesh = NavMesh.CalculateTriangulation();

            List<Vector3> navProbeList = new List<Vector3>(navMesh.vertices);
            
            foreach (Vector3 probe in navProbeList)
            {
                if (isInsideVolume(probe))
                {
                    lightProbePositions.Add(new Vector3(probe.x, probe.y + 0.4f, probe.z));
                }
            }
        }

        private void ObjectBoundsPlacement()
        {
            GameObject[] sceneObjects = UnityEngine.Object.FindObjectsOfType<GameObject>();
            Vector3 min = new Vector3();
            Vector3 max = new Vector3();
            foreach (GameObject obj in sceneObjects)
            {
                if (obj.isStatic && obj.GetComponent<Renderer>() != null)
                {
                    min = obj.GetComponent<Renderer>().bounds.min;
                    max = obj.GetComponent<Renderer>().bounds.max;
                    
                    lightProbePositions.Add(min);
                    lightProbePositions.Add(max);

                    lightProbePositions.Add(new Vector3(min.x, min.y, max.z));
                    lightProbePositions.Add(new Vector3(min.x, max.y, max.z));

                    lightProbePositions.Add(new Vector3(max.x, min.y, max.z));
                    lightProbePositions.Add(new Vector3(min.x, max.y, min.z));

                    lightProbePositions.Add(new Vector3(max.x, max.y, min.z));
                    lightProbePositions.Add(new Vector3(max.x, min.y, min.z));
                }
            }
        }

        private void VolumeScatterPlacement()
        {
            for (int x = 1; x <= bBoxSize.x; x += generationResolution)
            {
                for (int y = 1; y <= bBoxSize.y; y += generationResolution)
                {
                    for (int z = 1; z <= bBoxSize.z; z += generationResolution)
                    {
                        lightProbePositions.Add(new Vector3(x - (bBoxSize.x / 2) + bBoxCenter.x, y - (bBoxSize.y / 2 ) + bBoxCenter.y, z - (bBoxSize.z / 2) + bBoxCenter.z));
                    }
                }
            }
        }

        private void RayCastPlacement()
        {
            MeshRenderer[] renderedObjects = FindObjectsOfType<MeshRenderer>();
            List<MeshCollider> tempColliders = new List<MeshCollider>();
            foreach (MeshRenderer obj in renderedObjects)
            {
                if (!obj.gameObject.GetComponent<MeshCollider>())
                {
                    tempColliders.Add(obj.gameObject.AddComponent<MeshCollider>());
                }
            }

            Light[] sceneLights = FindObjectsOfType<Light>();
            foreach (Light light in sceneLights)
            {
                if (light.gameObject.activeInHierarchy == false)
                {
                    continue;
                }
                if (light.lightmapBakeType == LightmapBakeType.Baked | light.lightmapBakeType == LightmapBakeType.Mixed)
                {
                    switch (light.type)
                    {
                        case LightType.Spot:
                            for (int i = 0; i < ((2 * light.spotAngle) / generationResolution); i++)
                            {
                                RaycastHit hit;
                                Ray ray = new Ray(light.transform.position, RandomSpotLightCirclePoint(light));
                                Physics.Raycast(ray, out hit, light.range, 1, QueryTriggerInteraction.Collide);
                                Vector3 last = light.transform.position;
                                
                                lightProbePositions.Add(Vector3.Lerp(light.transform.position, new Vector3(hit.point.x, hit.point.y + 0.1f, hit.point.z), 0.9f));
                                lightProbePositions.Add(Vector3.Lerp(light.transform.position, new Vector3(hit.point.x, hit.point.y + 0.1f, hit.point.z), 0.4f));
                            }
                            break;
                        case LightType.Point:
                            for (int i = 0; i < ((8 * light.spotAngle) / generationResolution); i++)
                            {
                                RaycastHit hit;
                                Ray ray = new Ray(light.transform.position, Random.insideUnitSphere);
                                Physics.Raycast(ray, out hit, light.range, 1, QueryTriggerInteraction.Collide);
                                Vector3 last = light.transform.position;

                                lightProbePositions.Add(Vector3.Lerp(light.transform.position, new Vector3(hit.point.x, hit.point.y + 0.1f, hit.point.z), 0.9f));
                                lightProbePositions.Add(Vector3.Lerp(light.transform.position, new Vector3(hit.point.x, hit.point.y + 0.1f, hit.point.z), 0.4f));
                            }
                            break;
                    }
                }
            }

            foreach (MeshCollider tempCollider in tempColliders)
            {
                DestroyImmediate(tempCollider);
            }
        }

        private bool isInsideVolume(Vector3 probePos)
        {
            bool passedCheck = true;

            if (!(
                (bBoxCenter.x - (bBoxSize.x / 2)) <= probePos.x && probePos.x <= (bBoxCenter.x + (bBoxSize.x / 2)) && 
                (bBoxCenter.y - (bBoxSize.y / 2)) <= probePos.y && probePos.y <= (bBoxCenter.y + (bBoxSize.y / 2)) && 
                (bBoxCenter.z - (bBoxSize.z / 2)) <= probePos.z && probePos.z <= (bBoxCenter.z + (bBoxSize.z / 2))
            ))
            {
                return false;
            }
            if (passedCheck)
            {
                return true;
            }
            return false;
        }

        private void RemoveInvalidProbes()
        {
            for (int i = lightProbePositions.Count - 1; i >= 0; i--)
            {
                if (Physics.CheckSphere(lightProbePositions[i], 0.33f, 1, QueryTriggerInteraction.Ignore) || !(isInsideVolume(lightProbePositions[i])))
                {
                    lightProbePositions.RemoveAt(i);
                }
            }
        }
        
        private Vector3 RandomSpotLightCirclePoint(Light light)
        {
             Vector2 circle = Random.insideUnitCircle * (Mathf.Tan(Mathf.Deg2Rad * light.spotAngle / 2) * light.range);
             return light.transform.position + light.transform.forward*light.range + light.transform.rotation * new Vector3(circle.x, circle.y);;
        }

        private void OnDrawGizmosSelected()
        {
            Gizmos.color = Color.cyan;
            Gizmos.DrawWireCube(bBoxCenter, bBoxSize);
            Gizmos.color = Color.white;
        }
    }
}
#endif