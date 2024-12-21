fn main() {
    #[cfg(feature = "apple")]
    {
        println!("cargo:rustc-link-arg=-fapple-link-rtlib");
        /* ---------- Foundation framework ------------------------------------ */
        println!("cargo:rustc-link-arg=-framework");
        println!("cargo:rustc-link-arg=Foundation");

        /* ---------- Metal backend frmework ---------------------------------- */
        println!("cargo:rustc-link-arg=-framework");
        println!("cargo:rustc-link-arg=MetalPerformanceShaders");
        println!("cargo:rustc-link-arg=-framework");
        println!("cargo:rustc-link-arg=MetalPerformanceShadersGraph");
        println!("cargo:rustc-link-arg=-framework");
        println!("cargo:rustc-link-arg=Metal");

        /* ---------- CoreML backend framework -------------------------------- */
        println!("cargo:rustc-link-arg=-framework");
        println!("cargo:rustc-link-arg=CoreML");
        println!("cargo:rustc-link-arg=-framework");
        println!("cargo:rustc-link-arg=Accelerate");
        println!("cargo:rustc-link-lib=sqlite3");
    }
}
