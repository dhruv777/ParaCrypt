#include "cuda_runtime.h"
#include "device_launch_parameters.h"
#include  <string.h>
#include <stdio.h>
#include <stdlib.h> 
#define buf_size 65536
#define threads 1024

__device__ void encrypt0(char *read_buf, char *write_buf, int start_index, int end_index)
{

	for (int i = start_index; i < end_index; i++)
	{
		int m = (read_buf[i] + i) % 256;
		write_buf[i] = m;
	}
}
__device__ void decrypt0(char *read_buf, char *write_buf, int start_index, int end_index)
{
	for (int i = start_index; i < end_index; i++)
	{
		int m = (read_buf[i] - i) % 256;
		write_buf[i] = m;
	}
}
__device__ void encrypt1(char *read_buf, char *write_buf, int key, int start_index, int end_index)
{
	for (int i = start_index; i<end_index; ++i)
	{
		write_buf[i] = (read_buf[i] - key) % 256;
	}
}

__device__ void decrypt1(char *read_buf, char *write_buf, int key, int start_index, int end_index)
{
	for (int i = start_index; i<end_index; ++i)
	{
		write_buf[i] = (read_buf[i] + key) % 256;
	}
}

__device__ void encrypt2(char *read_buf, char *write_buf, int key, int start_index, int end_index)
{
	for (int i = start_index; i<end_index; ++i)
	{
		write_buf[i] = read_buf[i] ^ key;
	}
}

__device__ void decrypt2(char *read_buf, char *write_buf, int key, int start_index, int end_index)
{
	for (int i = start_index; i<end_index; ++i)
	{
		write_buf[i] = read_buf[i] ^ key;
	}
}
__device__ void encrypt3(char *read_buf, char *write_buf, int key, int start_index, int end_index)
{
	for (int i = start_index; i<end_index; ++i)
	{
		write_buf[i] = (key - read_buf[i]) % 256;
	}
}

__device__ void decrypt3(char *read_buf, char *write_buf, int key, int start_index, int end_index)
{
	for (int i = start_index; i<end_index; ++i)
	{
		write_buf[i] = (key - read_buf[i]) % 256;
	}
}
__global__ void encryption_1(char *read_buf, char *write_buf, int *read_size)
{
	int rank = threadIdx.x;
	int r2 = blockIdx.x;
	int block_size = buf_size / blockDim.x;
	int start_index, end_index;
	start_index = rank * block_size + r2*gridDim.x;
	if (start_index < (*read_size))
	{
		end_index = start_index + buf_size / (gridDim.x*blockDim.x);
		end_index = (end_index <= (*read_size)) ? end_index : (*read_size);
		printf("RANK : %d, start index : %d, end_index : %d\n", rank, start_index, end_index);
		int enc = rank % 8;


		switch (enc)
		{
		case 0: encrypt0(read_buf, write_buf, start_index, end_index);
			break;
		case 1: encrypt1(read_buf, write_buf, 0xFACA, start_index, end_index);
			break;
		case 2: encrypt2(read_buf, write_buf, 0xEFFE, start_index, end_index);
			break;
		case 3: encrypt3(read_buf, write_buf, 0xBFED, start_index, end_index);
			break;
		case 4: encrypt2(read_buf, write_buf, 0xCBDB, start_index, end_index);
			break;
		case 5: encrypt3(read_buf, write_buf, 0xDADA, start_index, end_index);
			break;
		case 6: encrypt0(read_buf, write_buf, start_index, end_index);
			break;
		case 7: encrypt1(read_buf, write_buf, 0xAFFD, start_index, end_index);
			break;
		}

	}
}
__global__ void decryption_1(char *read_buf, char *write_buf, int *read_size)
{
	int rank = threadIdx.x;
	int r2 = blockIdx.x;
	int block_size = buf_size / blockDim.x;
	int start_index, end_index;
	start_index = rank * block_size + r2*gridDim.x;
	if (start_index < (*read_size))
	{
		end_index = start_index + buf_size / (gridDim.x*blockDim.x);
		end_index = (end_index <= (*read_size)) ? end_index : (*read_size);
		printf("RANK : %d, start index : %d, end_index : %d\n", rank, start_index, end_index);
		int enc = rank % 8;

		switch (enc)
		{
		case 0: decrypt0(read_buf, write_buf, start_index, end_index);
			break;
		case 1: decrypt1(read_buf, write_buf, 0xFACA, start_index, end_index);
			break;
		case 2: decrypt2(read_buf, write_buf, 0xEFFE, start_index, end_index);
			break;
		case 3: decrypt3(read_buf, write_buf, 0xBFED, start_index, end_index);
			break;
		case 4: decrypt2(read_buf, write_buf, 0xCBDB, start_index, end_index);
			break;
		case 5: decrypt3(read_buf, write_buf, 0xDADA, start_index, end_index);
			break;
		case 6: decrypt0(read_buf, write_buf, start_index, end_index);
			break;
		case 7: decrypt1(read_buf, write_buf, 0xAFFD, start_index, end_index);
			break;
		}

	}
}
int main()
{
	FILE *fp, *fpw;
	char filename[50], buf[buf_size], new_data[buf_size];
	char *d_a, *d_b;
	fprintf(stdout, "-------------------------------------------------PARACRYPT--------------------------------------------\n\n");
	int *d_size, choice, flag = 1, read_size;
	fflush(stdout);
	do
	{
		fprintf(stdout, "1. Encrypt a File\n2. Decrypt a File\n3. Exit\n");
		fflush(stdout);
		scanf("%d", &choice);
		if (choice == 3)
			exit(0);
		else if (choice == 1 || choice == 2)
			break;
		else
			printf("Invalid Option. Try Again.\n");
	} while (true);
	fprintf(stdout, "Enter File Name : ");
	fflush(stdout);
	scanf("%s", filename);
	if ((fp = fopen(filename, "rb")) == NULL)
	{
		printf("Invalid Filename.\n");
		exit(0);
	}
	//start = time_t();
	fseek(fp, 0, SEEK_END); // seek to end of file
	int fsz = ftell(fp); // get current file pointer
	fseek(fp, 0, SEEK_SET);
	printf("\nFile Size : %d bytes\n", fsz);
	int tread = 0;
	cudaEvent_t start, stop;
	cudaEventCreate(&start);
	cudaEventCreate(&stop);
	cudaEventRecord(start, 0);

	if (choice == 1)
	{
		fprintf(stdout, "Encrypting File %s.\n\n", filename);
		char nf[50] = "e_";
		strcat(nf, filename);
		fpw = fopen(nf, "w+b");
	}
	else
	{
		char nf[50];
		strcpy(nf, filename);
		nf[0] = 'd';
		fprintf(stdout, "Decrypting File %s.\n\n", filename);
		fpw = fopen(nf, "w+b");
	}

	if (choice == 1)
	{
		while (flag)
		{

			read_size = fread(buf, sizeof(char), buf_size, fp);
			if (read_size == 0)
			{
				double q = (double)tread / fsz;
				fprintf(stdout, "\rPlease Wait    ... %0.1lf%%", q * 100);
				fprintf(stdout, "\nFile Successfully Encrypted\n");
				//fprintf(stdout, "Read Size : %d\n", read_size);
				fflush(stdout);
				flag = 0;
				break;
			}
			else
			{
				cudaMalloc((void**)&d_a, read_size * sizeof(char));
				cudaMalloc((void**)&d_b, read_size * sizeof(char));
				cudaMalloc((void **)&d_size, sizeof(int));
				double q = (double)tread / fsz;
				fprintf(stdout, "\rPlease Wait    ... %0.1lf%%", q * 100);
				tread += read_size;
				//fprintf(stdout, "Read Size : %d\n", read_size);
				fflush(stdout);
				cudaMemcpy(d_a, buf, read_size * sizeof(char), cudaMemcpyHostToDevice);
				cudaMemcpy(d_size, &read_size, sizeof(int), cudaMemcpyHostToDevice);
				encryption_1 << <8, threads >> >(d_a, d_b, d_size);
				cudaMemcpy(new_data, d_b, read_size * sizeof(char), cudaMemcpyDeviceToHost);
				//printf("Buffer size %d, READ sIZe :%d\n", strlen(new_data),read_size);
				// printf("%s",new_data);
				//printf("%s", new_data);
				fwrite(new_data, sizeof(char), read_size, fpw);
				cudaFree(d_a);
				cudaFree(d_b);
				cudaFree(d_size);
			}
		}
	}
	else
	{
		while (flag)
		{

			read_size = fread(buf, sizeof(char), buf_size, fp);
			if (read_size == 0)
			{
				double q = (double)tread / fsz;
				fprintf(stdout, "\rPlease Wait    ... %0.1lf%%", q * 100);
				fprintf(stdout, "\nFile Successfully Decrypted\n");
				//fprintf(stdout, "Read Size : %d\n", read_size);
				fflush(stdout);
				flag = 0;
				break;
			}
			else
			{
				cudaMalloc((void**)&d_a, read_size * sizeof(char));
				cudaMalloc((void**)&d_b, read_size * sizeof(char));
				cudaMalloc((void **)&d_size, sizeof(int));
				double q = (double)tread / fsz;
				fprintf(stdout, "\rPlease Wait    ... %0.1lf%%", q * 100);
				tread += read_size;
				//fprintf(stdout, "Read Size : %d\n", read_size);
				fflush(stdout);
				cudaMemcpy(d_a, buf, read_size * sizeof(char), cudaMemcpyHostToDevice);
				cudaMemcpy(d_size, &read_size, sizeof(int), cudaMemcpyHostToDevice);
				decryption_1 << <8, threads >> >(d_a, d_b, d_size);
				cudaMemcpy(new_data, d_b, read_size * sizeof(char), cudaMemcpyDeviceToHost);
				//printf("Buffer size %d, READ sIZe :%d\n", strlen(new_data),read_size);
				// printf("%s",new_data);
				//printf("%s", new_data);
				fwrite(new_data, sizeof(char), read_size, fpw);
				cudaFree(d_a);
				cudaFree(d_b);
				cudaFree(d_size);
			}
		}
	}
	// end = time_t();
	cudaEventRecord(stop, 0);
	cudaEventSynchronize(stop);
	float elapsedTime;
	cudaEventElapsedTime(&elapsedTime, start, stop);
	printf("Time Taken : %f", elapsedTime / 1000);
	fclose(fpw);
	fclose(fp);
	getchar();
	getchar();
	return 0;
}