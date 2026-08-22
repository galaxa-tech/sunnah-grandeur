"use client";

import { useState, useEffect } from "react";
import Sidebar from "@/components/Sidebar";
import Header from "@/components/Header";
import { collection, onSnapshot, addDoc, deleteDoc, doc, serverTimestamp } from "firebase/firestore";
import { db } from "@/lib/firebase";

interface MediaItem {
  id: string;
  name: string;
  type: string;
  size?: string;
  path: string;
  url: string;
}

export default function MediaManagementPage() {
  const [mediaItems, setMediaItems] = useState<MediaItem[]>([]);
  const [loading, setLoading] = useState(true);
  
  // Modal State
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [name, setName] = useState("");
  const [type, setType] = useState("Image");
  const [url, setUrl] = useState("");

  useEffect(() => {
    setLoading(true);
    const unsubscribe = onSnapshot(collection(db, "media"), (snapshot) => {
      const list: MediaItem[] = [];
      snapshot.forEach((doc) => {
        list.push({ id: doc.id, ...doc.data() } as MediaItem);
      });
      setMediaItems(list);
      setLoading(false);
    }, (error) => {
      console.error("Error fetching media:", error);
      setLoading(false);
    });

    return () => unsubscribe();
  }, []);

  const handleAddMedia = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!name || !url) return;
    try {
      await addDoc(collection(db, "media"), {
        name,
        type,
        path: url,
        url: url,
        size: "External",
        createdAt: serverTimestamp()
      });
      setIsModalOpen(false);
      setName("");
      setUrl("");
    } catch (e) {
      console.error("Error adding media:", e);
    }
  };

  const handleDelete = async (id: string) => {
    if (!window.confirm("Are you sure you want to delete this media asset?")) return;
    try {
      await deleteDoc(doc(db, "media", id));
    } catch (e) {
      console.error("Error deleting media:", e);
    }
  };

  return (
    <div className="flex">
      <Sidebar />
      <main className="ml-64 flex-1 flex flex-col min-h-screen relative bento-pattern overflow-hidden">
        <Header title="Media Library" />

        <div className="p-8 max-w-[1400px] mx-auto w-full relative z-10 space-y-6">
          <div className="flex justify-between items-center bg-surface-card p-6 rounded-xl border border-border-subtle shadow-xl">
            <div>
              <h3 className="font-headline-md text-xl text-on-background">Media Assets & Gallery</h3>
              <p className="text-xs text-on-surface-variant mt-1">Manage luxury banner photos, product high-res images, and video assets.</p>
            </div>
            <button
              onClick={() => setIsModalOpen(true)}
              className="flex items-center gap-2 bg-primary text-on-primary px-6 py-2.5 rounded font-label-accent text-xs hover:brightness-110 transition-all shadow-lg shadow-primary/20"
            >
              <span className="material-symbols-outlined text-base">cloud_upload</span>
              ADD ASSET LINK
            </button>
          </div>

          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-6">
            {loading ? (
              <div className="col-span-full p-12 text-center text-on-surface-variant">
                <div className="animate-spin rounded-full h-8 w-8 border-t-2 border-primary mx-auto mb-4"></div>
                Loading live media...
              </div>
            ) : mediaItems.length === 0 ? (
              <div className="col-span-full p-12 text-center text-on-surface-variant bg-surface-container rounded-xl">
                No media items found. Click 'Add Asset Link' to add one.
              </div>
            ) : (
              mediaItems.map((item) => (
                <div key={item.id} className="bg-surface-card border border-border-subtle rounded-xl overflow-hidden group hover:border-primary/50 transition-colors relative">
                  <div className="h-40 bg-surface-container-high flex items-center justify-center relative border-b border-border-subtle overflow-hidden">
                    {item.type === "Image" ? (
                      <img src={item.url || item.path} alt={item.name} className="w-full h-full object-cover group-hover:scale-105 transition-transform" />
                    ) : (
                      <span className="material-symbols-outlined text-4xl text-primary/60 group-hover:scale-110 transition-transform">
                        {item.type === "Video" ? "play_circle" : "audiotrack"}
                      </span>
                    )}
                    <button 
                      onClick={() => handleDelete(item.id)}
                      className="absolute top-2 right-2 bg-red-500/80 text-white rounded-full w-8 h-8 flex items-center justify-center opacity-0 group-hover:opacity-100 transition-opacity hover:bg-red-600"
                    >
                      <span className="material-symbols-outlined text-sm">delete</span>
                    </button>
                  </div>
                  <div className="p-4 space-y-2">
                    <h4 className="font-semibold text-sm text-on-background truncate">{item.name}</h4>
                    <div className="flex justify-between text-xs text-on-surface-variant font-mono">
                      <span>{item.type}</span>
                      <span>{item.size || "External"}</span>
                    </div>
                  </div>
                </div>
              ))
            )}
          </div>
        </div>
        
        {/* Add Media Modal */}
        {isModalOpen && (
          <div className="fixed inset-0 z-[100] bg-black/90 backdrop-blur-sm overflow-y-auto flex items-center justify-center">
            <div className="max-w-[500px] w-full mx-6 bg-surface-card border border-border-subtle rounded-2xl shadow-2xl">
              <div className="px-8 py-6 border-b border-border-subtle flex justify-between items-center">
                <h2 className="font-headline-lg text-xl text-primary">Add Asset Link</h2>
                <button 
                  onClick={() => setIsModalOpen(false)}
                  className="text-on-surface-variant hover:text-primary transition-colors"
                >
                  <span className="material-symbols-outlined">close</span>
                </button>
              </div>
              <form onSubmit={handleAddMedia} className="p-8 space-y-6">
                <div className="space-y-2">
                  <label className="block text-xs font-label-accent text-primary tracking-widest uppercase">Asset Name</label>
                  <input 
                    value={name} onChange={(e) => setName(e.target.value)}
                    className="w-full bg-[#1A1A1A] border border-outline-variant rounded px-4 py-3 text-sm focus:outline-none focus:border-primary"
                    placeholder="e.g. Hero Banner 2" required 
                  />
                </div>
                <div className="space-y-2">
                  <label className="block text-xs font-label-accent text-primary tracking-widest uppercase">Type</label>
                  <select 
                    value={type} onChange={(e) => setType(e.target.value)}
                    className="w-full bg-[#1A1A1A] border border-outline-variant rounded px-4 py-3 text-sm focus:outline-none focus:border-primary"
                  >
                    <option value="Image">Image</option>
                    <option value="Video">Video</option>
                    <option value="Audio">Audio</option>
                  </select>
                </div>
                <div className="space-y-2">
                  <label className="block text-xs font-label-accent text-primary tracking-widest uppercase">Direct URL</label>
                  <input 
                    value={url} onChange={(e) => setUrl(e.target.value)}
                    className="w-full bg-[#1A1A1A] border border-outline-variant rounded px-4 py-3 text-sm focus:outline-none focus:border-primary"
                    placeholder="https://..." required type="url"
                  />
                </div>
                <div className="pt-4 flex justify-end gap-4">
                  <button type="button" onClick={() => setIsModalOpen(false)} className="text-on-surface-variant text-xs">CANCEL</button>
                  <button type="submit" className="bg-primary text-on-primary px-6 py-2 rounded text-xs">SAVE ASSET</button>
                </div>
              </form>
            </div>
          </div>
        )}
      </main>
    </div>
  );
}
