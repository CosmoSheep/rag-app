#!/usr/bin/env python3
"""
ingest.py - 向量化脚本
从 data.txt 读取内容，切分后生成向量并存入 faiss_index 目录
"""
import os
from langchain_community.document_loaders import TextLoader
from langchain.text_splitter import RecursiveCharacterTextSplitter
from langchain_openai import OpenAIEmbeddings
from langchain_community.vectorstores import FAISS

def main():
    # 检查 API Key
    if not os.getenv("OPENAI_API_KEY"):
        raise ValueError("请设置环境变量 OPENAI_API_KEY")
    
    print("📖 正在加载 data.txt...")
    loader = TextLoader("data.txt", encoding="utf-8")
    documents = loader.load()
    
    print("✂️  正在切分文档...")
    text_splitter = RecursiveCharacterTextSplitter(
        chunk_size=500,
        chunk_overlap=50,
        length_function=len,
    )
    chunks = text_splitter.split_documents(documents)
    print(f"   切分为 {len(chunks)} 个文本块")
    
    print("🔢 正在生成向量...")
    embeddings = OpenAIEmbeddings(model="text-embedding-ada-002")
    
    print("💾 正在构建 FAISS 索引...")
    vectorstore = FAISS.from_documents(chunks, embeddings)
    
    print("💿 正在保存到 faiss_index 目录...")
    vectorstore.save_local("faiss_index")
    
    print("✅ 完成！faiss_index 已生成")

if __name__ == "__main__":
    main()

