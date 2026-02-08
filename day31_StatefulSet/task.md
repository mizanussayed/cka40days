# StatefulSet in Kubernetes
stateful applications require stable network identities and persistent storage. Kubernetes provides StatefulSets to manage the deployment and scaling of such applications. In this assignment, you will deploy a MongoDB StatefulSet with persistent storage.

### 1. Create a Headless Service
Create a headless service for your MongoDB StatefulSet deployment. A headless service is required to provide network identity to each Pod in the StatefulSet.

### 2. Create PersistentVolumes and StorageClass

Configure persistent storage for your StatefulSet by:
- Creating a StorageClass
- Setting up 5 PersistentVolumes to be used by your StatefulSet

### 3. Deploy a MongoDB StatefulSet

Create and deploy a StatefulSet manifest that:
- Uses the MongoDB image
- References the headless service created earlier
- Configures persistent storage using volumeClaimTemplates
- Starts with 3 replicas

### 4. Verify and Test the Deployment

- Confirm all Pods are running
- Verify PersistentVolumeClaims are bound to your PersistentVolumes
- Connect to one of the MongoDB instances and create some sample data
- Test persistence by deleting a Pod and verifying data remains after the Pod is recreated

### 5. Scale the StatefulSet

- Scale the StatefulSet to 5 replicas
- Observe the ordered creation of new Pods
- Verify the new Pods have their own PersistentVolumeClaims bound to PersistentVolumes
