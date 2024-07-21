# Expediting Spark with GPU in CDE

The integration of GPUs into Spark environments, facilitated by frameworks like NVIDIA's RAPIDS, aims to offload compute-intensive ETL tasks such as data processing, filtering, aggregation from CPUs to GPUs. Tasks that typically require extensive computational resources can be completed significantly faster with GPU acceleration, leading to more responsive data pipelines and enhanced real-time analytics capabilities.

Since CDE is seamlessly integrated with an HDFS cluster by default, users have the flexibility to utilize the CDE UI, API, or CLI for executing Spark jobs on a compute platform, powered by Kubernetes. This allows them to access data sources from the HDFS cluster and then store the resulting outputs back into the HDFS cluster.

## Steps & Results

1. You may taint the node with GPU and tag the CDE job with the associated toleration label.
   ```
   $ kubectl taint nodes worker-18 nvidia.com/gpu=true:NoSchedule
   $ kubectl taint nodes worker-19 nvidia.com/gpu=true:NoSchedule
   $ kubectl taint nodes worker-20 nvidia.com/gpu=true:NoSchedule
   $ kubectl taint nodes worker-21 nvidia.com/gpu=true:NoSchedule
   ```

   Verify the tainted nodes.
   ```
   $ kubectl get nodes -o=jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.spec.taints[*].key}{"\n"}{end}' | grep nvidia.com

   worker-18	nvidia.com/gpu
   worker-19	nvidia.com/gpu
   worker-20	nvidia.com/gpu
   worker-21	nvidia.com/gpu
   ```

   Alternatively, Kubernetes can automatically select a node with GPU available to run the Spark job.

2. In CDE, create the resource folder to store the application file(s). In this example, I use the data transformation scripts from [Nvidia-Spark github](https://github.com/NVIDIA/spark-rapids-benchmarks/tree/dev/nds).

<img width="1401" alt="image" src="https://github.com/user-attachments/assets/20d76008-85ca-41fe-bb7b-066ca0099894">

3. Create a job with the necessary arguments and parameters. You may also fine-tune the Spark job’s configuration settings for improved performancethe based on the published [guide](https://docs.nvidia.com/spark-rapids/user-guide/23.10/tuning-guide.html).

<img width="518" alt="image" src="https://github.com/user-attachments/assets/66399b36-7ad6-44dd-8469-5df054d0ea31">

   Note that the job is also configured with the defined GPU taint.

<img width="677" alt="image" src="https://github.com/user-attachments/assets/76fdf708-1f29-4033-a714-e6ffbe5c3421">

4. Run the Spark job.

<img width="1401" alt="image" src="https://github.com/user-attachments/assets/3c104b09-3fd1-46e1-8f6c-e98050389800">

5. Verify that the tasks are making use of GPU in the embedded Spark UI interface.

![image](https://github.com/user-attachments/assets/d357b483-6285-4777-a714-900bd0591574)

## Bonus Track #1: Realtime GPU monitoring

Always keep the GPU busy!
So, how can we know whether the running job is actively using the GPU or falling back to the CPU at any given time?
You may include useful Python library in the CDE job. In this example, I create a Python environment with nvitop module to monitor the realtime GPU utilization inside the Spark executor. 

<img width="1400" alt="image" src="https://github.com/user-attachments/assets/09d0b464-0cad-49eb-a03d-ab68ec68daac">

<img width="549" alt="image" src="https://github.com/user-attachments/assets/e8dbdce8-6b30-4a3c-8096-42898eebad01">

In the K8s cluster, you may run nvitop inside the spark-container container of the Spark job executor pod. Example as follows:

```
$ kubectl -n dex-app-t2hxcx7h exec -ti nds-transcode-parquet-8b409b90d44ed4a7-exec-1   -c spark-container -- /bin/bash
```
<img width="1433" alt="image" src="https://github.com/user-attachments/assets/f1d27e4d-fdb9-448b-8685-d87be568e74f">

## OpenShift: Openshift Metrics

Openshift offers a variety of infrastructure metrics. For GPU monitoring over a substantial period of time, you can use the DCGM module as depicted below.

![image](https://github.com/user-attachments/assets/937fd0fc-b5c1-4513-8004-812a7dbda9d0)



## Caveats

Achieving optimal performance with GPU-accelerated Spark requires careful consideration of data types, compatibility with GPU-specific operations, and efficient memory management. Certain data types, such as decimals or non-UTF-8 encoded data in the case of CSV files, may present compatibility challenges that require preprocessing or adjustments to ensure smooth operation with GPU-accelerated frameworks like RAPIDS. 
