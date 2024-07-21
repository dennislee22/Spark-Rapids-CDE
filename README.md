# Expediting Spark job with GPU in CDE

The integration of GPUs into Spark environments, facilitated by frameworks like NVIDIA's RAPIDS, aims to offload compute-intensive ETL tasks such as data processing, filtering, aggregation from CPU to GPU. Tasks that typically require extensive computational resources can be completed significantly faster with GPU acceleration, leading to more responsive data pipelines and enhanced real-time analytics capabilities.

Since CDE is seamlessly integrated with an HDFS cluster by default, users have the flexibility to utilize the CDE UI, API, or CLI for executing Spark jobs on a compute platform, powered by Kubernetes. This allows them to access data sources from the HDFS cluster and then store the resulting outputs back into the HDFS cluster, for subsequent consumption.

<img width="672" alt="image" src="https://github.com/user-attachments/assets/1dd4321b-823f-4c72-b04b-ad9f6f37dfae">

## Prerequisites

1. Capture/Generate the raw data and store it in the HDFS cluster. In this example, I generate the raw data using `nds_gen_data.py` script adapted from [Nvidia-Spark github](https://github.com/NVIDIA/spark-rapids-benchmarks/tree/dev/nds). The sample outcome is as follows.

   ```
   $ hdfs dfs -ls /user/dennislee/tpcds/raw_sf100
   Found 25 items
   drwxr-xr-x   - dennislee dennislee          0 2024-07-17 08:06 /user/dennislee/tpcds/raw_sf100/call_center
   drwxr-xr-x   - dennislee dennislee          0 2024-07-17 08:06 /user/dennislee/tpcds/raw_sf100/catalog_page
   drwxr-xr-x   - dennislee dennislee          0 2024-07-17 08:07 /user/dennislee/tpcds/raw_sf100/catalog_returns
   drwxr-xr-x   - dennislee dennislee          0 2024-07-17 08:09 /user/dennislee/tpcds/raw_sf100/catalog_sales
   drwxr-xr-x   - dennislee dennislee          0 2024-07-17 08:10 /user/dennislee/tpcds/raw_sf100/customer
   drwxr-xr-x   - dennislee dennislee          0 2024-07-17 08:10 /user/dennislee/tpcds/raw_sf100/customer_address
   drwxr-xr-x   - dennislee dennislee          0 2024-07-17 08:10 /user/dennislee/tpcds/raw_sf100/customer_demographics
   drwxr-xr-x   - dennislee dennislee          0 2024-07-17 08:10 /user/dennislee/tpcds/raw_sf100/date_dim
   drwxr-xr-x   - dennislee dennislee          0 2024-07-17 08:10 /user/dennislee/tpcds/raw_sf100/dbgen_version
   drwxr-xr-x   - dennislee dennislee          0 2024-07-17 08:10 /user/dennislee/tpcds/raw_sf100/household_demographics
   drwxr-xr-x   - dennislee dennislee          0 2024-07-17 08:10 /user/dennislee/tpcds/raw_sf100/income_band
   drwxr-xr-x   - dennislee dennislee          0 2024-07-17 08:10 /user/dennislee/tpcds/raw_sf100/inventory
   drwxr-xr-x   - dennislee dennislee          0 2024-07-17 08:10 /user/dennislee/tpcds/raw_sf100/item
   drwxr-xr-x   - dennislee dennislee          0 2024-07-17 08:10 /user/dennislee/tpcds/raw_sf100/promotion
   drwxr-xr-x   - dennislee dennislee          0 2024-07-17 08:10 /user/dennislee/tpcds/raw_sf100/reason
   drwxr-xr-x   - dennislee dennislee          0 2024-07-17 08:10 /user/dennislee/tpcds/raw_sf100/ship_mode
   drwxr-xr-x   - dennislee dennislee          0 2024-07-17 08:10 /user/dennislee/tpcds/raw_sf100/store
   drwxr-xr-x   - dennislee dennislee          0 2024-07-17 08:11 /user/dennislee/tpcds/raw_sf100/store_returns
   drwxr-xr-x   - dennislee dennislee          0 2024-07-17 08:24 /user/dennislee/tpcds/raw_sf100/store_sales
   drwxr-xr-x   - dennislee dennislee          0 2024-07-17 08:24 /user/dennislee/tpcds/raw_sf100/time_dim
   drwxr-xr-x   - dennislee dennislee          0 2024-07-17 08:24 /user/dennislee/tpcds/raw_sf100/warehouse
   drwxr-xr-x   - dennislee dennislee          0 2024-07-17 08:24 /user/dennislee/tpcds/raw_sf100/web_page
   drwxr-xr-x   - dennislee dennislee          0 2024-07-17 08:25 /user/dennislee/tpcds/raw_sf100/web_returns
   drwxr-xr-x   - dennislee dennislee          0 2024-07-17 08:30 /user/dennislee/tpcds/raw_sf100/web_sales
   drwxr-xr-x   - dennislee dennislee          0 2024-07-17 08:30 /user/dennislee/tpcds/raw_sf100/web_site
   ```

2. You may taint the node(s) with GPU and tag the CDE job with the associated toleration label.
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

   Alternatively (without taint and toleration), K8s will automatically select a node with GPU available to run the Spark job that requires GPU.
   
## Steps & Results

1. In CDE, create the resource folder to store the application file(s). In this example, I use the data transformation scripts from [Nvidia-Spark github](https://github.com/NVIDIA/spark-rapids-benchmarks/tree/dev/nds).

<img width="1401" alt="image" src="https://github.com/user-attachments/assets/20d76008-85ca-41fe-bb7b-066ca0099894">

2. Create a job with the necessary arguments and parameters. You may also fine-tune the Spark job’s configuration settings for improved performance based on the published [guide](https://docs.nvidia.com/spark-rapids/user-guide/23.10/tuning-guide.html).

<img width="540" alt="image" src="https://github.com/user-attachments/assets/1cd10889-4d11-4dcf-ae35-62bb73e03413">

   Note that the job is also configured with the defined GPU taint.

<img width="677" alt="image" src="https://github.com/user-attachments/assets/76fdf708-1f29-4033-a714-e6ffbe5c3421">

3. Run the defined Spark job.

<img width="743" alt="image" src="https://github.com/user-attachments/assets/a454b88e-73bb-4576-bc08-a2aef82e405f">

4. Verify that the tasks are making use of GPU in the embedded Spark UI interface.

![image](https://github.com/user-attachments/assets/b46e7bfb-4d38-40c2-acaf-77ad485d8033)

![image](https://github.com/user-attachments/assets/d357b483-6285-4777-a714-900bd0591574)

5. The job is completed.

<img width="695" alt="image" src="https://github.com/user-attachments/assets/3f30ec3d-bcff-4e16-a198-d4d85cad9b32">


## Bonus Track #1: Realtime GPU monitoring

**Keep the GPU busy! Accelerate Spark!**
So, how can we know whether the running job is actively using the GPU or falling back to the CPU at any given time? In this example, I create a Python environment with `nvitop` module to monitor the realtime GPU utilization inside the Spark executor. 

<img width="1400" alt="image" src="https://github.com/user-attachments/assets/09d0b464-0cad-49eb-a03d-ab68ec68daac">

After that, add the built Python environment into the Spark job configuration as follows.

<img width="549" alt="image" src="https://github.com/user-attachments/assets/e8dbdce8-6b30-4a3c-8096-42898eebad01">

In the K8s cluster, you may run nvitop inside the spark-container container of the Spark job executor pod. Example as follows:

```
$ kubectl -n dex-app-t2hxcx7h exec -ti nds-transcode-parquet-8b409b90d44ed4a7-exec-1  -c spark-container -- /bin/bash
```
<img width="1433" alt="image" src="https://github.com/user-attachments/assets/f1d27e4d-fdb9-448b-8685-d87be568e74f">

## Bonus Track #2: Openshift Metrics

Openshift offers a variety of infrastructure metrics. For GPU monitoring over a substantial period of time, you can use the DCGM module as depicted below.

![image](https://github.com/user-attachments/assets/937fd0fc-b5c1-4513-8004-812a7dbda9d0)


## Caveat

Achieving optimal performance with GPU-accelerated Spark requires careful consideration of data types, compatibility with GPU-specific operations, and efficient memory management. Certain data types, such as decimals or non-UTF-8 encoded data in the case of CSV files, may present compatibility challenges that require preprocessing or adjustments to ensure smooth operation with GPU-accelerated frameworks like RAPIDS. 

For instance, the above Spark job was configured with `spark.rapids.sql.explain=NOT_ON_GPU` field to find out which task cannot run on GPU. As a result, the following log was generated.

```
24/07/21 03:12:35 WARN GpuOverrides: 
  !Exec <ShuffleExchangeExec> cannot run on GPU because Columnar exchange without columnar children is inefficient
    @Partitioning <HashPartitioning> could run on GPU
      @Expression <AttributeReference> cr_returned_date_sk#1132 could run on GPU
    !Exec <FileSourceScanExec> cannot run on GPU because unsupported data types DecimalType(7,2) [cr_return_amount, cr_net_loss, cr_return_amt_inc_tax, cr_store_credit, cr_fee, cr_refunded_cash, cr_return_ship_cost, cr_return_tax, cr_reversed_charge] in read for CSV; GpuCSVScan only supports UTF8 encoded data
```
