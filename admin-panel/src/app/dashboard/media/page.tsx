"use client";

import { useState, useEffect } from "react";
import Sidebar from "@/components/Sidebar";
import Header from "@/components/Header";
import { collection, onSnapshot, addDoc, deleteDoc, doc, serverTimestamp } from "firebase/firestore";
import { db } from "@/lib/firebase";

// Matches app-mobile/lib/models/video_model.dart + MediaProvider._firestoreFetch —
// this is the ONLY path content reaches the app's Media tab (no YouTube API,
// no algorithmic suggestions, by design). Every field here is read by name
// on the app side, so it has to match exactly.
interface MediaItem {
  id: string;
  type: "video" | "quran" | "ruqyah";
  title: string;
  author: string;
  category: string;
  description: string;
  youtubeId: string;
  isActive: boolean;
}

const SECTIONS: { value: MediaItem["type"]; label: string }[] = [
  { value: "video", label: "Islamic Videos" },
  { value: "quran", label: "Quran" },
  { value: "ruqyah", label: "Ruqyah" },
];

function extractYoutubeId(input: string): string | null {
  const trimmed = input.trim();
  const patterns = [
    /(?:youtube\.com\/watch\?v=|youtube\.com\/embed\/|youtube\.com\/shorts\/)([\w-]{11})/,
    /youtu\.be\/([\w-]{11})/,
  ];
  for (const re of patterns) {
    const match = trimmed.match(re);
    if (match) return match[1];
  }
  // Bare 11-character video ID pasted directly
  if (/^[\w-]{11}$/.test(trimmed)) return trimmed;
  return null;
}

export default function MediaManagementPage() {
  const [mediaItems, setMediaItems] = useState<MediaItem[]>([]);
  const [loading, setLoading] = useState(true);

  const [isModalOpen, setIsModalOpen] = useState(false);
  const [section, setSection] = useState<MediaItem["type"]>("video");
  const [title, setTitle] = useState("");
  const [author, setAuthor] = useState("");
  const [category, setCategory] = useState("");
  const [youtubeInput, setYoutubeInput] = useState("");
  const [description, setDescription] = useState("");
  const [formError, setFormError] = useState("");
  const [saving, setSaving] = useState(false);

  useEffect(() => {
    setLoading(true);
    const unsubscribe = onSnapshot(collection(db, "media"), (snapshot) => {
      const list: MediaItem[] = [];
      snapshot.forEach((d) => {
        list.push({ id: d.id, ...d.data() } as MediaItem);
      });
      setMediaItems(list);
      setLoading(false);
    }, (error) => {
      console.error("Error fetching media:", error);
      setLoading(false);
    });

    return () => unsubscribe();
  }, []);

  const resetForm = () => {
    setSection("video");
    setTitle("");
    setAuthor("");
    setCategory("");
    setYoutubeInput("");
    setDescription("");
    setFormError("");
  };

  const handleAddMedia = async (e: React.FormEvent) => {
    e.preventDefault();
    setFormError("");
    const youtubeId = extractYoutubeId(youtubeInput);
    if (!youtubeId) {
      setFormError("Couldn't find a valid YouTube video ID in that link.");
      return;
    }
    if (!title.trim()) {
      setFormError("Title is required.");
      return;
    }
    setSaving(true);
    try {
      await addDoc(collection(db, "media"), {
        type: section,
        title: title.trim(),
        author: author.trim() || "Sunnah Grandeur",
        category: category.trim() || SECTIONS.find((s) => s.value === section)?.label,
        description: description.trim(),
        youtubeId,
        duration: "—",
        views: "0",
        thumbnail: `https://img.youtube.com/vi/${youtubeId}/hqdefault.jpg`,
        isActive: true,
        publishedAt: serverTimestamp(),
        createdAt: serverTimestamp(),
      });
      setIsModalOpen(false);
      resetForm();
    } catch (err) {
      console.error("Error adding media:", err);
      setFormError("Failed to save — please try again.");
    } finally {
      setSaving(false);
    }
  };

  const handleDelete = async (id: string) => {
    if (!window.confirm("Remove this video from the app's Media tab?")) return;
    try {
      await deleteDoc(doc(db, "media", id));
    } catch (e) {
      console.error("Error deleting media:", e);
    }
  };

  return (
    <div className="flex">
      <Sidebar />
      <main className="ml-0 md:ml-64 flex-1 flex flex-col min-h-screen relative bento-pattern overflow-hidden">
        <Header title="Media Library" />

        <div className="p-8 max-w-[1400px] mx-auto w-full relative z-10 space-y-6">
          <div className="flex justify-between items-center bg-surface-card p-6 rounded-xl border border-border-subtle shadow-xl">
            <div>
              <h3 className="font-headline-md text-xl text-on-background">Mobile App Media Tab</h3>
              <p className="text-xs text-on-surface-variant mt-1">
                Videos added here are the only content that appears in the app&apos;s Media tab — no automated
                suggestions, no YouTube algorithm. Add a video, and it shows up there right away.
              </p>
            </div>
            <button
              onClick={() => setIsModalOpen(true)}
              className="flex items-center gap-2 bg-primary text-on-primary px-6 py-2.5 rounded font-label-accent text-xs hover:brightness-110 transition-all shadow-lg shadow-primary/20 shrink-0"
            >
              <span className="material-symbols-outlined text-base">add</span>
              ADD VIDEO
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
                No videos added yet. Click &apos;Add Video&apos; to add the first one.
              </div>
            ) : (
              mediaItems.map((item) => (
                <div key={item.id} className="bg-surface-card border border-border-subtle rounded-xl overflow-hidden group hover:border-primary/50 transition-colors relative">
                  <div className="h-40 bg-surface-container-high flex items-center justify-center relative border-b border-border-subtle overflow-hidden">
                    {item.youtubeId ? (
                      <img
                        src={`https://img.youtube.com/vi/${item.youtubeId}/hqdefault.jpg`}
                        alt={item.title}
                        className="w-full h-full object-cover group-hover:scale-105 transition-transform"
                      />
                    ) : (
                      <span className="material-symbols-outlined text-4xl text-primary/60">play_circle</span>
                    )}
                    <button
                      onClick={() => handleDelete(item.id)}
                      className="absolute top-2 right-2 bg-red-500/80 text-white rounded-full w-8 h-8 flex items-center justify-center opacity-0 group-hover:opacity-100 transition-opacity hover:bg-red-600"
                    >
                      <span className="material-symbols-outlined text-sm">delete</span>
                    </button>
                    <span className="absolute bottom-2 left-2 bg-black/70 text-white text-[10px] uppercase tracking-widest px-2 py-1 rounded">
                      {SECTIONS.find((s) => s.value === item.type)?.label ?? item.type}
                    </span>
                  </div>
                  <div className="p-4 space-y-1">
                    <h4 className="font-semibold text-sm text-on-background truncate">{item.title}</h4>
                    <p className="text-xs text-on-surface-variant truncate">{item.author}</p>
                  </div>
                </div>
              ))
            )}
          </div>
        </div>

        {isModalOpen && (
          <div className="fixed inset-0 z-[100] bg-black/90 backdrop-blur-sm overflow-y-auto flex items-center justify-center p-4">
            <div className="max-w-[500px] w-full bg-surface-card border border-border-subtle rounded-2xl shadow-2xl">
              <div className="px-8 py-6 border-b border-border-subtle flex justify-between items-center">
                <h2 className="font-headline-lg text-xl text-primary">Add Video</h2>
                <button
                  onClick={() => { setIsModalOpen(false); resetForm(); }}
                  className="text-on-surface-variant hover:text-primary transition-colors"
                >
                  <span className="material-symbols-outlined">close</span>
                </button>
              </div>
              <form onSubmit={handleAddMedia} className="p-8 space-y-5">
                {formError && (
                  <div className="bg-red-500/10 border border-red-500/20 text-red-400 text-xs rounded-lg p-3">
                    {formError}
                  </div>
                )}
                <div className="space-y-2">
                  <label className="block text-xs font-label-accent text-primary tracking-widest uppercase">App Section</label>
                  <select
                    value={section}
                    onChange={(e) => setSection(e.target.value as MediaItem["type"])}
                    className="w-full bg-[#1A1A1A] border border-outline-variant rounded px-4 py-3 text-sm focus:outline-none focus:border-primary"
                  >
                    {SECTIONS.map((s) => (
                      <option key={s.value} value={s.value}>{s.label}</option>
                    ))}
                  </select>
                </div>
                <div className="space-y-2">
                  <label className="block text-xs font-label-accent text-primary tracking-widest uppercase">YouTube Link or Video ID</label>
                  <input
                    value={youtubeInput} onChange={(e) => setYoutubeInput(e.target.value)}
                    className="w-full bg-[#1A1A1A] border border-outline-variant rounded px-4 py-3 text-sm focus:outline-none focus:border-primary"
                    placeholder="https://youtube.com/watch?v=..." required
                  />
                </div>
                <div className="space-y-2">
                  <label className="block text-xs font-label-accent text-primary tracking-widest uppercase">Title</label>
                  <input
                    value={title} onChange={(e) => setTitle(e.target.value)}
                    className="w-full bg-[#1A1A1A] border border-outline-variant rounded px-4 py-3 text-sm focus:outline-none focus:border-primary"
                    placeholder="e.g. The Etiquette of Seeking Knowledge" required
                  />
                </div>
                <div className="grid grid-cols-2 gap-4">
                  <div className="space-y-2">
                    <label className="block text-xs font-label-accent text-primary tracking-widest uppercase">Scholar / Channel</label>
                    <input
                      value={author} onChange={(e) => setAuthor(e.target.value)}
                      className="w-full bg-[#1A1A1A] border border-outline-variant rounded px-4 py-3 text-sm focus:outline-none focus:border-primary"
                      placeholder="e.g. Mufti Menk"
                    />
                  </div>
                  <div className="space-y-2">
                    <label className="block text-xs font-label-accent text-primary tracking-widest uppercase">Series / Topic</label>
                    <input
                      value={category} onChange={(e) => setCategory(e.target.value)}
                      className="w-full bg-[#1A1A1A] border border-outline-variant rounded px-4 py-3 text-sm focus:outline-none focus:border-primary"
                      placeholder="e.g. Tafseer"
                    />
                  </div>
                </div>
                <div className="space-y-2">
                  <label className="block text-xs font-label-accent text-primary tracking-widest uppercase">Description (optional)</label>
                  <textarea
                    value={description} onChange={(e) => setDescription(e.target.value)}
                    rows={2}
                    className="w-full bg-[#1A1A1A] border border-outline-variant rounded px-4 py-3 text-sm focus:outline-none focus:border-primary resize-none"
                  />
                </div>
                <div className="pt-2 flex justify-end gap-4">
                  <button type="button" onClick={() => { setIsModalOpen(false); resetForm(); }} className="text-on-surface-variant text-xs">CANCEL</button>
                  <button type="submit" disabled={saving} className="bg-primary text-on-primary px-6 py-2 rounded text-xs disabled:opacity-50">
                    {saving ? "SAVING..." : "ADD VIDEO"}
                  </button>
                </div>
              </form>
            </div>
          </div>
        )}
      </main>
    </div>
  );
}
