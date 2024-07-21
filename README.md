# Expediting Spark with GPU in CDE

The integration of GPUs into Spark environments, facilitated by frameworks like NVIDIA's RAPIDS, aims to offload compute-intensive ETL tasks such as data processing, filtering, aggregation from CPUs to GPUs. Tasks that typically require extensive computational resources can be completed significantly faster with GPU acceleration, leading to more responsive data pipelines and enhanced real-time analytics capabilities.

Since CDE is seamlessly integrated with an HDFS cluster by default, users have the flexibility to utilize the CDE UI, API, or CLI for executing Spark jobs on a compute platform, powered by Kubernetes. This allows them to access data sources from the HDFS cluster and then store the resulting outputs back into the HDFS cluster.

## Steps & Results

1. You may taint the node with GPU and tag the CDE job with the associated toleration label. Alternatively, Kubernetes can automatically select a node with GPUs available to host the Spark job. In this example, the GPU nodes in my environment have been tainted with `nvidia.com/gpu=true` label.

2. 

```
$ kubectl get nodes -o=jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.spec.taints[*].key}{"\n"}{end}' | grep nvidia.com

worker-18	nvidia.com/gpu
worker-19	nvidia.com/gpu
worker-20	nvidia.com/gpu
worker-21	nvidia.com/gpu
```



## Caveats

Achieving optimal performance with GPU-accelerated Spark requires careful consideration of data types, compatibility with GPU-specific operations, and efficient memory management. Certain data types, such as decimals or non-UTF-8 encoded data in the case of CSV files, may present compatibility challenges that require preprocessing or adjustments to ensure smooth operation with GPU-accelerated frameworks like RAPIDS. 
